"""Per-host TOML resolution, including unsafe hostnames and migration priority."""
import json
import pathlib
import shutil
import subprocess
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
HELPER = ROOT / "Helpers/SettingsPaths.js"


def call_helper(fn, *args):
    source = HELPER.read_text().replace(".pragma library", "")
    program = source + f"\nprocess.stdout.write(JSON.stringify({fn}(...{json.dumps(list(args))})));"
    return json.loads(subprocess.check_output(["node", "-e", program], text=True))


@unittest.skipIf(shutil.which("node") is None, "node not installed")
class SettingsPathTests(unittest.TestCase):
    def test_hosts_keep_separate_toml_files(self):
        self.assertEqual(call_helper("resolveSettingsFile", "", "/cfg", "laptop"), "/cfg/settings/laptop.toml")
        self.assertNotEqual(call_helper("resolveSettingsFile", "", "/cfg", "desk"), call_helper("resolveSettingsFile", "", "/cfg", "laptop"))

    def test_override_wins(self):
        self.assertEqual(call_helper("resolveSettingsFile", "/custom.toml", "/cfg", "laptop"), "/custom.toml")

    def test_new_hosts_only_use_toml_seed(self):
        self.assertEqual(call_helper("seedFiles", "/cfg"), ["/cfg/defaults.toml"])

    def test_hostile_hostname_stays_inside_settings_directory(self):
        path = pathlib.Path(call_helper("resolveSettingsFile", "", "/cfg", "../../evil'; touch pwned; '"))
        self.assertEqual(path.parent, pathlib.Path("/cfg/settings"))
        self.assertEqual(path.suffix, ".toml")
