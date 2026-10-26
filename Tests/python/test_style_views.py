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

    def test_sidebar_transition_shares_one_animation(self):
        source = (ROOT / "Modules/Panels/Settings/SettingsContent.qml").read_text()
        self.assertIn("Behavior on sidebarExpansion", source)
        self.assertIn("spacing: root.material ? root.materialRail.rowSpacing : Style.marginXS", source)
        self.assertIn("SettingsWindowLayout.materialRail(sidebarExpansion,", source)
        self.assertEqual(source.count("SettingsWindowLayout.railIconInset(root.sidebarExpansion,"), 2)
        self.assertIn("opacity: root.material ? root.sidebarExpansion", source)
        self.assertIn("enabled: !root.material", source)

    def test_home_profile_places_host_in_center_and_distribution_on_right(self):
        source = (ROOT / "Modules/Panels/Settings/SettingsHome.qml").read_text()
        profile = source[source.index("id: profileRow"):source.index("id: categories")]
        self.assertIn("HostService.hostName", source)
        self.assertIn("text: root.profile.name", profile)
        self.assertIn("anchors.centerIn: parent", profile)
        self.assertIn("text: root.profile.hostname", profile)
        self.assertIn("anchors.right: parent.right", profile)
        self.assertIn("text: root.profile.os", profile)
        self.assertIn("source: HostService.osLogo", profile)

    def test_home_profile_matches_username_font_and_avatar_size(self):
        source = (ROOT / "Modules/Panels/Settings/SettingsHome.qml").read_text()
        profile = source[source.index("id: profileRow"):source.index("id: categories")]
        self.assertIn("id: profileName", profile)
        self.assertEqual(profile.count("font: profileName.font"), 2)
        self.assertEqual(profile.count("color: profileName.color"), 2)
        self.assertIn("Layout.preferredWidth: profileAvatar.width", profile)
        self.assertIn("Layout.preferredHeight: profileAvatar.height", profile)

    def test_home_profile_spans_two_category_columns(self):
        source = (ROOT / "Modules/Panels/Settings/SettingsHome.qml").read_text()
        self.assertIn("Layout.preferredWidth: categories.geometry.profileWidth", source)
        self.assertRegex(source, r"Layout.preferredWidth: categories\.geometry\.profileWidth\s+Layout.alignment: Qt.AlignHCenter")

    def test_home_profile_has_no_dot_separators(self):
        source = (ROOT / "Modules/Panels/Settings/SettingsHome.qml").read_text()
        profile = source[source.index("id: profileRow"):source.index("id: categories")]
        self.assertNotIn("model: [1 / 3, 2 / 3]", profile)
        self.assertEqual(profile.count("width: parent.width / 3"), 2)


    def test_home_promotes_general_and_about_with_centered_contents(self):
        source = (ROOT / "Modules/Panels/Settings/SettingsHome.qml").read_text()
        self.assertIn("entry: root.homeTabs.general", source)
        self.assertIn("entry: root.homeTabs.about", source)
        self.assertIn("model: root.homeTabs.grid", source)
        self.assertIn("SettingsPanel.Tab.General, SettingsPanel.Tab.About", source)
        self.assertIn("onChosen: tabIndex => root.tabRequested(tabIndex)", source)
        self.assertIn("category.compact ? Qt.AlignHCenter : Qt.AlignLeft", source)
        self.assertIn("category.compact ? Text.AlignHCenter : Text.AlignLeft", source)
        self.assertIn("category.compact ? parent.verticalCenter : undefined", source)

    def test_escape_uses_settings_navigation_before_closing(self):
        window = (ROOT / "Modules/Panels/Settings/SettingsPanelWindow.qml").read_text()
        shortcut = window[window.index('sequence: "Escape"'):].split("Shortcut {", 1)[0]
        self.assertIn("onActivated: settingsContent.handleEscape()", shortcut)
        self.assertNotIn("closeWindow()", shortcut)
        content = (ROOT / "Modules/Panels/Settings/SettingsContent.qml").read_text()
        handler = content[content.index("function handleEscape()"):content.index("function openTabIndex(")]
        self.assertIn("SettingsWindowLayout.escapeAction(searchText, homeVisible)", handler)
        self.assertIn('searchInput.text = ""', handler)
        self.assertIn("showHome()", handler)
        self.assertIn("closeRequested()", handler)

    def test_sidebar_viewport_does_not_collapse_during_page_reveal(self):
        source = (ROOT / "Modules/Panels/Settings/SettingsContent.qml").read_text()
        self.assertIn("SettingsSidebarLayout {", source)
        self.assertIn("viewportWidth: sidebar.expandedWidth", source)
        self.assertIn("Layout.preferredWidth: pageTransition.progress * expandedWidth", source)
        self.assertIn("model: root.tabsModel", source)
        self.assertNotIn("SettingsSidebarDebug", source)

    def test_registered_views_exist(self):
        source = (ROOT / "Helpers/UiStyles.js").read_text()
        paths = re.findall(r'"(?:controlCenter|mediaCard|mediaPlayer|osd|notificationContent|kdeConnectHome)": "([^"]+\.qml)"', source)
        self.assertEqual(len(paths), 18)
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
