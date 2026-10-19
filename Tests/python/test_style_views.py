"""Every registered style surface has a real renderer and a shared entrypoint."""
import pathlib
import re
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]


class StyleViewTests(unittest.TestCase):
    def test_settings_styles_share_direct_category_navigation(self):
        source = (ROOT / "Modules/Panels/Settings/SettingsContent.qml").read_text()
        self.assertIn("model: root.tabsModel", source)
        self.assertIn("root.openTabIndex(index);", source)
        self.assertIn("readonly property bool selected: !root.homeVisible && index === root.currentTabIndex", source)
        self.assertNotIn("materialNavigation", source)
        self.assertNotIn("materialOverview", source)
        self.assertIn("Layout.preferredWidth: pageTransition.progress * expandedWidth", source)
        self.assertIn("opacity: 1 - pageTransition.progress", source)
        self.assertIn("active: contentLayout.visible && index === root.currentTabIndex", source)
        toolbar = source.split("id: settingsToolbar", 1)[1].split("// Sidebar", 1)[0]
        self.assertIn("id: sidebarToggle", toolbar)
        self.assertIn("id: searchInput", toolbar)
        self.assertIn("id: toolbarClose", toolbar)
        self.assertNotIn("searchContainerWrapper", source)

    def test_registered_views_exist(self):
        source = (ROOT / "Helpers/UiStyles.js").read_text()
        paths = re.findall(r'"(?:controlCenter|mediaCard|mediaPlayer|osd|notificationContent|kdeConnectHome)": "([^"]+\.qml)"', source)
        self.assertEqual(len(paths), 12)
        for path in paths:
            with self.subTest(path=path):
                self.assertTrue((ROOT / path).is_file())

    def test_panel_entrypoints_load_registered_surfaces(self):
        for path, surface in (("Modules/Panels/ControlCenter/ControlCenterPanel.qml", "controlCenter"),
                              ("Modules/Panels/Media/MediaPlayerPanel.qml", "mediaPlayer"),
                              ("Modules/Cards/MediaCard.qml", "mediaCard"),
                              ("Modules/Panels/KdeConnect/KdeConnectContent.qml", "kdeConnectHome")):
            with self.subTest(path=path):
                source = (ROOT / path).read_text()
                self.assertIn(f'surface: "{surface}"', source)
                self.assertNotIn("Style.materialControls", source)

    def test_material_media_is_separate_from_system_monitor(self):
        source = (ROOT / "Modules/Panels/ControlCenter/MaterialControlCenter.qml").read_text()
        self.assertIn("sourceComponent: MediaCard", source)
        self.assertIn("sourceComponent: MaterialSystemMonitor", source)
        legacy = (ROOT / "Modules/Panels/ControlCenter/CaelestiaControlCenter.qml").read_text()
        self.assertIn("SystemMonitorCard", legacy)

    def test_material_header_buttons_are_spaced(self):
        # Material icon buttons have a filled background, so they need a gap.
        # The header buttons sit in NPill, whose row has a non-zero gap by default.
        pill = (ROOT / "Widgets/NPill.qml").read_text()
        row = re.search(r"id: row\n\s+anchors.centerIn: parent\n\s+spacing: (.+)", pill)
        self.assertIsNotNone(row)
        self.assertNotEqual(row.group(1).strip(), "0")
        for path in ("Modules/Panels/ControlCenter/MaterialControlHeader.qml", "Modules/Panels/KdeConnect/MaterialKdeConnectHome.qml"):
            source = (ROOT / path).read_text()
            self.assertIn("NPill {", source, path)
            self.assertNotRegex(source, r"spacing: 0\b", path)
