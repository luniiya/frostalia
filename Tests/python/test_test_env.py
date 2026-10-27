"""Scripts/dev/test-env.sh, the nested-Hyprland test environment, and its virtual pointer."""
import importlib.util
import pathlib
import re
import struct
import subprocess
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "Scripts/dev/test-env.sh"
POINTER = ROOT / "Scripts/dev/test_env_pointer.py"

spec = importlib.util.spec_from_file_location("test_env_pointer", POINTER)
pointer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(pointer)


class ScriptTests(unittest.TestCase):
    def test_script_parses(self):
        subprocess.run(["bash", "-n", str(SCRIPT)], check=True)

    def test_never_kills_by_config_path(self):
        # The real shell runs this same checkout through ~/.config/quickshell/frostalia,
        # so a `qs -p <checkout> kill` could take it down with the test shell
        text = SCRIPT.read_text(encoding="utf-8")
        self.assertNotRegex(text, r"qs -p \"\$ROOT\" kill")
        self.assertIn('qs kill --pid "$pid"', text)

    def test_shell_runs_on_copies_and_a_private_bus(self):
        text = SCRIPT.read_text(encoding="utf-8")
        self.assertIn("FROSTALIA_CONFIG_DIR=$DIR/config/", text)
        self.assertIn("FROSTALIA_CACHE_DIR=$DIR/cache/", text)
        self.assertIn("dbus-run-session", text)

    def test_default_size_matches_pointer_defaults(self):
        size = re.search(r'FROSTALIA_TEST_ENV_SIZE:-(\d+)x(\d+)', SCRIPT.read_text(encoding="utf-8"))
        text = POINTER.read_text(encoding="utf-8")
        self.assertIn('"--width", type=int, default=%s' % size.group(1), text)
        self.assertIn('"--height", type=int, default=%s' % size.group(2), text)


class WireTests(unittest.TestCase):
    def test_string_is_length_prefixed_nul_terminated_and_padded(self):
        data = pointer.wl_string("wl_seat")
        self.assertEqual(struct.unpack_from("<I", data)[0], 8)
        self.assertEqual(data[4:12], b"wl_seat\0")
        self.assertEqual(len(data) % 4, 0)

    def test_string_round_trip(self):
        for text in ["", "a", "abc", "zwlr_virtual_pointer_manager_v1"]:
            payload = pointer.wl_string(text) + struct.pack("<I", 7)
            value, offset = pointer.string_at(payload, 0)
            self.assertEqual(value, text)
            self.assertEqual(struct.unpack_from("<I", payload, offset)[0], 7)


if __name__ == "__main__":
    unittest.main()
