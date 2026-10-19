"""Hooks live under General and search results navigate to that subtab."""
import json
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]


class GeneralHooksTests(unittest.TestCase):
    def test_hooks_are_a_general_subtab(self):
        general = (ROOT / "Modules/Panels/Settings/Tabs/GeneralTab.qml").read_text()
        self.assertIn('text: I18n.tr("panels.hooks.title")', general)
        self.assertIn("HooksSubTab {}", general)
        self.assertFalse((ROOT / "Modules/Panels/Settings/Tabs/Hooks").exists())
        for name in ("SettingsContent.qml", "SettingsPanel.qml"):
            source = (ROOT / "Modules/Panels/Settings" / name).read_text()
            self.assertNotIn("Tab.Hooks", source)
            self.assertNotIn("hooksTab", source)
        self.assertNotIn("Tab.Hooks", (ROOT / "Services/Control/IPCService.qml").read_text())

    def test_disabled_hooks_can_still_be_enabled(self):
        source = (ROOT / "Modules/Panels/Settings/Tabs/General/HooksSubTab.qml").read_text()
        toggle = source.index("  NToggle {")
        self.assertNotIn("enabled: Settings.data.hooks.enabled", source[:toggle])
        self.assertIn("onToggled: checked => Settings.data.hooks.enabled = checked", source)
        self.assertEqual(source.count("  HookRow {"), source.count("    enabled: Settings.data.hooks.enabled"))

    def test_search_results_point_to_general_hooks(self):
        index = json.loads((ROOT / "Assets/settings-search-index.json").read_text())
        hooks = [entry for entry in index if entry["labelKey"].startswith("panels.hooks.")]
        self.assertGreaterEqual(len(hooks), 7)
        for entry in hooks:
            with self.subTest(label=entry["labelKey"]):
                self.assertEqual(entry["tabLabel"], "common.general")
                self.assertEqual(entry["subTab"], 3)
                self.assertEqual(entry["subTabLabel"], "panels.hooks.title")
