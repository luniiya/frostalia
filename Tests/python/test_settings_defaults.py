"""Commons/Settings.qml is the single source of built-in setting defaults.

The settings store snapshots the JsonAdapter before loading the host's TOML and
Settings.getDefaultValue() reads that snapshot, which every settings "reset"
button uses. These tests read the same tree through settings_defaults.
"""

import json
import os
import pathlib
import re
import subprocess
import tempfile
import unittest

import settings_defaults

ROOT = pathlib.Path(__file__).resolve().parents[2]
SETTINGS_QML = ROOT / "Commons" / "Settings.qml"


def default_value_paths():
    """Yield (file, path) for every literal Settings.getDefaultValue("...") call."""
    for path in sorted(ROOT.glob("**/*.qml")):
        if "Tests" in path.relative_to(ROOT).parts:
            continue
        for key in re.findall(r'Settings\.getDefaultValue\("([^"]+)"\)', path.read_text(encoding="utf-8")):
            yield str(path.relative_to(ROOT)), key


def style_default_paths():
    # Style folders supply their own defaults for these, see Helpers/UiStyleSettings.js
    source = (ROOT / "Helpers/UiStyleSettings.js").read_text(encoding="utf-8")
    appearance = json.loads(re.search(r"var defaults = (\{.*?\n\});", source, re.S).group(1))
    return {f"{section}.{key}" for section, fields in appearance.items() for key in fields}


class SettingsDefaultsTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.defaults = settings_defaults.defaults()

    def test_parser_reads_the_whole_adapter(self):
        self.assertEqual(settings_defaults.lookup("bar.barType"), "simple")
        self.assertIsInstance(settings_defaults.lookup("bar.notchGap"), (int, float))
        self.assertIsInstance(settings_defaults.lookup("radialMenu.items"), list)
        self.assertIsInstance(settings_defaults.lookup("controlCenter.cards"), list)
        self.assertIsInstance(settings_defaults.lookup("settingsVersion"), int)
        # Enum members resolve to their index, as QML stores them
        self.assertTrue(all(isinstance(t, int) for t in settings_defaults.lookup("osd.enabledTypes")))
        self.assertGreater(len(self.defaults), 20)

    def test_lookup_reports_missing_paths(self):
        with self.assertRaises(KeyError):
            settings_defaults.lookup("bar.noSuchSetting")
        with self.assertRaises(KeyError):
            settings_defaults.lookup("bar.barType.deeper")

    def test_no_json_defaults_file(self):
        self.assertFalse((ROOT / "Assets/settings-default.json").exists())
        source = SETTINGS_QML.read_text(encoding="utf-8")
        self.assertNotIn("settings-default.json", source)
        self.assertIn("SettingsObject.valueAt(settingsStore.defaults, path)", source)

    def test_every_reset_button_has_a_default(self):
        # A path missing from Settings.qml makes the reset button reset to undefined
        styled = style_default_paths()
        missing = []
        for file, path in default_value_paths():
            if path in styled:
                continue
            try:
                settings_defaults.lookup(path)
            except KeyError:
                missing.append(f"{file}: {path}")
        self.assertEqual(missing, [])

    def test_defaults_round_trip_through_the_toml_store(self):
        target = pathlib.Path(os.environ.get("CARGO_TARGET_DIR", ROOT / "Tools/settings/target"))
        helper = target / "debug/frostalia-settings"
        if not helper.exists():
            self.skipTest("run cargo test for Tools/settings first")
        with tempfile.TemporaryDirectory(prefix="frostalia-defaults-") as directory:
            config = pathlib.Path(directory) / "host.toml"
            for settings in (self.defaults, {}):
                request = json.dumps({"settings": settings, "baseline": None})
                result = subprocess.run([str(helper), "load", str(config)], input=request + "\n",
                                        text=True, check=True, capture_output=True)
            self.assertEqual(json.loads(result.stdout)["settings"], self.defaults)

    def test_session_menu_default_actions(self):
        options = settings_defaults.lookup("sessionMenu.powerOptions")
        enabled = [option for option in options if option["enabled"]]
        self.assertEqual([option["action"] for option in enabled],
                         ["lock", "shutdown", "reboot", "rebootToUefi"])
        self.assertEqual([option["keybind"] for option in enabled], ["1", "2", "3", "4"])
        self.assertTrue(all(option["keybind"] == "" for option in options if not option["enabled"]))
        self.assertEqual(len({option["action"] for option in options}), 8)
        ui = (ROOT / "Modules/Panels/Settings/Tabs/SessionMenu/SessionMenuTab.qml").read_text(encoding="utf-8")
        ui_defaults = dict(re.findall(r'"id": "([^"\n]+)",\s*"text": [^\n]+\n\s*"enabled": (true|false)', ui))
        self.assertEqual(ui_defaults, {option["action"]: str(option["enabled"]).lower() for option in options})

    def test_screen_corners_black_by_default(self):
        self.assertIs(settings_defaults.lookup("general.forceBlackScreenCorners"), True)


if __name__ == "__main__":
    unittest.main()
