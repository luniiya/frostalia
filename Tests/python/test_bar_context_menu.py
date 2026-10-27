"""The empty bar's default menu opens settings or desktop widget editing."""
import json
import pathlib
import unittest

import settings_defaults

ROOT = pathlib.Path(__file__).resolve().parents[2]


class BarContextMenuTests(unittest.TestCase):
    def test_menu_is_default_and_reset_option(self):
        defaults = settings_defaults.defaults()
        self.assertEqual(defaults["bar"]["rightClickAction"], "contextMenu")
        ui = (ROOT / "Modules/Panels/Settings/Tabs/Bar/BehaviorSubTab.qml").read_text()
        self.assertIn('"key": "contextMenu"', ui)
        self.assertIn('defaultValue: Settings.getDefaultValue("bar.rightClickAction")', ui)

    def test_menu_opens_at_click_and_updates_desktop_editing(self):
        source = (ROOT / "Modules/Bar/Bar.qml").read_text()
        self.assertIn("emptyBarMenuAnchor.x = mouse.x", source)
        self.assertIn("emptyBarMenuAnchor.y = mouse.y", source)
        self.assertIn("PanelService.showContextMenu(emptyBarMenu, emptyBarMenuAnchor, root.screen)", source)
        self.assertIn("SettingsPanelService.openHome()", source)
        self.assertIn("Settings.data.desktopWidgets.enabled = next.enabled", source)
        self.assertIn("DesktopWidgetRegistry.editMode = next.editing", source)
        self.assertIn("if (bar.isPointOverWidget(mouse.x, mouse.y))", source)

    def test_default_migration_is_registered(self):
        source = (ROOT / "Commons/Migrations/MigrationRegistry.qml").read_text()
        self.assertIn("72: migration72Component", source)
        self.assertIn("migration72Component: Migration72", source)
        migration = (ROOT / "Commons/Migrations/Migration72.qml").read_text()
        self.assertIn("BarContextMenu.migrateRightClickAction(rawJson?.bar?.rightClickAction)", migration)

    def test_menu_labels_are_translated(self):
        english = json.loads((ROOT / "Assets/Translations/en.json").read_text())
        for key in ("edit-desktop-widgets", "finish-editing-desktop-widgets"):
            self.assertIn(key, english["actions"])
