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
        self.assertEqual(default, "material")
        self.assertEqual(defaults["ui"]["style"], default)
        self.assertTrue((ROOT / "Styles" / default / "Definition.qml").is_file())

    def test_style_names_have_english_translations(self):
        english = json.loads((ROOT / "Assets/Translations/en.json").read_text())
        keys = [key for path in (ROOT / "Styles").glob("*/Definition.qml")
                for key in re.findall(r'labelKey: "([^"]+)"', path.read_text())]
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
        self.assertIn("Settings.setUiStyle(key)", tab)
        self.assertIn("Style.uiStyleChoices", tab)

    def test_style_defaults_match_the_reference_defaults(self):
        source = (ROOT / "Helpers/UiStyleSettings.js").read_text()
        appearance = json.loads(re.search(r"var defaults = (\{.*?\n\});", source, re.S).group(1))
        reference = json.loads((ROOT / "Assets/settings-default.json").read_text())
        for section, fields in appearance.items():
            for key, value in fields.items():
                with self.subTest(path=f"{section}.{key}"):
                    self.assertEqual(value, reference[section][key])
        self.assertNotIn("scaleRatio", appearance["general"])
        self.assertNotIn("fontDefaultScale", appearance["ui"])
        self.assertNotIn("fontFixedScale", appearance["ui"])
        # Every control in the UI subtabs must persist with its style.
        tabs = ROOT / "Modules/Panels/Settings/Tabs/UserInterface"
        for name in ("AppearanceSubTab.qml", "PanelsSubTab.qml"):
            for section, key in re.findall(r"Settings.data.(general|ui).(\w+)", (tabs / name).read_text()):
                self.assertIn(key, appearance[section], f"{name}: {section}.{key}")

    def test_caelestia_is_gone(self):
        self.assertEqual([], sorted(str(p.relative_to(ROOT)) for p in ROOT.rglob("Caelestia*.qml")))
        self.assertNotIn("caelestia", (ROOT / "Helpers/UiStyles.js").read_text().lower())
        self.assertNotIn('"orbit"', (ROOT / "Helpers/RadialMenu.js").read_text())

    def test_control_centers_share_the_notification_feed(self):
        folder = ROOT / "Modules/Panels/ControlCenter"
        self.assertFalse((folder / "MaterialNotificationFeed.qml").exists())
        self.assertIn("NotificationFeed {}", (folder / "MaterialControlCenter.qml").read_text())
        feed = (folder / "NotificationFeed.qml").read_text()
        self.assertIn('Style.surfaceUrl("notificationContent")', feed)
        self.assertNotIn("MaterialNotificationContent", feed)

    def test_screen_corners_are_host_settings_in_general(self):
        source = (ROOT / "Helpers/UiStyleSettings.js").read_text()
        for key in ("showScreenCorners", "forceBlackScreenCorners", "screenRadiusRatio"):
            self.assertNotIn(f'"{key}"', source)
        index = json.loads((ROOT / "Assets/settings-search-index.json").read_text())
        corners = [entry for entry in index if entry["labelKey"].startswith("panels.general.screen-corners-")]
        self.assertEqual(len(corners), 3)
        for entry in corners:
            self.assertEqual(entry["tabLabel"], "common.general")
            self.assertEqual(entry["subTab"], 2)
        self.assertFalse((ROOT / "Modules/Panels/Settings/Tabs/UserInterface/ScreenCornersSubTab.qml").exists())

    def test_font_selectors_import_their_service(self):
        tab = (ROOT / "Modules/Panels/Settings/Tabs/UserInterface/AppearanceSubTab.qml").read_text()
        self.assertIn("import qs.Services.System", tab)
        self.assertIn("FontService.availableFonts", tab)
        self.assertIn("FontService.monospaceFonts", tab)
        service = (ROOT / "Services/System/FontService.qml").read_text()
        self.assertIn("for (const family of UiStyles.fontFamilies(UiStyleRegistry.definitions))", service)

    def test_font_families_are_in_ui_and_scales_remain_general(self):
        index = json.loads((ROOT / "Assets/settings-search-index.json").read_text())
        for field in ("default", "monospace"):
            family = next(entry for entry in index if entry["labelKey"] == f"panels.general.fonts-{field}-label")
            scale = next(entry for entry in index if entry["labelKey"] == f"panels.general.fonts-{field}-scale-label")
            self.assertEqual(family["tabLabel"], "panels.user-interface.title")
            self.assertEqual(scale["tabLabel"], "common.general")

    def test_style_selector_is_searchable(self):
        index = json.loads((ROOT / "Assets/settings-search-index.json").read_text())
        entries = [entry for entry in index if entry.get("labelKey") == "panels.user-interface.ui-style-label"]
        self.assertEqual(len(entries), 1)
        self.assertEqual(entries[0]["descriptionKey"], "panels.user-interface.ui-style-description")
        self.assertIsNone(entries[0]["subTab"])


if __name__ == "__main__":
    unittest.main()
