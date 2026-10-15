"""UI style registration, saved defaults and Settings discovery stay connected."""
import json
import pathlib
import re
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]


class UiStyleTests(unittest.TestCase):
    def test_default_style_is_registered(self):
        defaults = json.loads((ROOT / "Assets/settings-default.json").read_text())
        helper = (ROOT / "Helpers/UiStyles.js").read_text()
        default = re.search(r'var defaultStyle = "([^"]+)"', helper).group(1)
        self.assertEqual(defaults["ui"]["style"], default)
        self.assertRegex(helper, r'"' + default + r'":\s*\{')

    def test_style_names_have_english_translations(self):
        helper = (ROOT / "Helpers/UiStyles.js").read_text()
        english = json.loads((ROOT / "Assets/Translations/en.json").read_text())
        keys = re.findall(r'"labelKey": "([^"]+)"', helper)
        self.assertTrue(keys)
        for key in keys:
            value = english
            for part in key.split("."):
                value = value[part]
            self.assertIsInstance(value, str)
            self.assertTrue(value)

    def test_style_selector_precedes_subtabs_and_can_reset(self):
        tab = (ROOT / "Modules/Panels/Settings/Tabs/UserInterface/UserInterfaceTab.qml").read_text()
        self.assertLess(tab.index('label: I18n.tr("panels.user-interface.ui-style-label")'), tab.index("NTabBar {"))
        self.assertIn('defaultValue: Settings.getDefaultValue("ui.style")', tab)
        self.assertIn("Settings.data.ui.style = key", tab)
        self.assertIn("Style.uiStyleChoices", tab)

    def test_style_selector_is_searchable(self):
        index = json.loads((ROOT / "Assets/settings-search-index.json").read_text())
        entries = [entry for entry in index if entry.get("labelKey") == "panels.user-interface.ui-style-label"]
        self.assertEqual(len(entries), 1)
        self.assertEqual(entries[0]["descriptionKey"], "panels.user-interface.ui-style-description")
        self.assertIsNone(entries[0]["subTab"])


if __name__ == "__main__":
    unittest.main()
