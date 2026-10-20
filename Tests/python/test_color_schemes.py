"""The default color scheme ships with the shell and matches the built-in fallback colors."""
import json
import pathlib
import re
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]


class ColorSchemeTests(unittest.TestCase):
    def default_scheme(self):
        return json.loads((ROOT / "Assets/settings-default.json").read_text())["colorSchemes"]["predefinedScheme"]

    def test_default_scheme_is_bundled(self):
        name = self.default_scheme()
        self.assertEqual(name, "Eldritch")
        self.assertTrue((ROOT / "Assets/ColorScheme" / name / f"{name}.json").is_file())

    def test_noctalia_scheme_is_bundled(self):
        self.assertTrue((ROOT / "Assets/ColorScheme/Noctalia/Noctalia.json").is_file())

    def test_fallback_colors_match_default_scheme(self):
        name = self.default_scheme()
        dark = json.loads((ROOT / "Assets/ColorScheme" / name / f"{name}.json").read_text())["dark"]
        color_qml = (ROOT / "Commons/ShellColors.qml").read_text()
        block = color_qml[color_qml.index("id: defaultColors"):]
        block = block[:block.index("\n  }\n")]
        fallback = dict(re.findall(r'readonly property color (m\w+): "(#[0-9A-Fa-f]+)"', block))
        self.assertTrue(fallback)
        for key, value in fallback.items():
            self.assertEqual(value.lower(), dark[key].lower(), key)


if __name__ == "__main__":
    unittest.main()
