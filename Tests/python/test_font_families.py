"""Text must render with the style-resolved fonts, not the raw (possibly empty) settings."""
import pathlib
import re
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]

# Files that need the saved value itself: the resolver, the font pickers and the debug info.
RAW_SETTING_USERS = {
    "Commons/Style.qml",
    "Modules/Panels/Settings/Tabs/UserInterface/AppearanceSubTab.qml",
    "Modules/Panels/Settings/Tabs/About/VersionSubTab.qml",
}
RAW_FONT = re.compile(r"Settings\.data\.ui\.font(Fixed|Default)\b(?!Scale)")


class FontFamilyTests(unittest.TestCase):
    def test_qml_uses_resolved_font_families(self):
        for path in ROOT.rglob("*.qml"):
            relative = path.relative_to(ROOT).as_posix()
            if relative in RAW_SETTING_USERS or relative.startswith(("Tools/", "Tests/")):
                continue
            for number, line in enumerate(path.read_text().splitlines(), 1):
                self.assertIsNone(RAW_FONT.search(line), f"{relative}:{number}: use Style.fontFixed/fontDefault")


if __name__ == "__main__":
    unittest.main()
