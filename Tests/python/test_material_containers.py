"""Material filled controls must stay visible on surface-variant backgrounds (settings pages)."""
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]


class MaterialContainerTests(unittest.TestCase):
    def test_filled_controls_use_tonal_container(self):
        for widget in ("Widgets/NTabButton.qml", "Widgets/NCollapsible.qml", "Widgets/NIconButton.qml",
                       "Widgets/NFieldBackground.qml", "Widgets/NMenuItemBackground.qml"):
            source = (ROOT / widget).read_text()
            self.assertIn("Color.mTonalContainer", source, widget)
            self.assertNotIn("? Color.mSurfaceVariant", source, widget)

    def test_fields_and_menus_use_shared_backgrounds(self):
        # Style the shared components, not each widget, so every field and menu matches.
        shared = {
            "Widgets/NTextInput.qml": ("NFieldBackground",),
            "Widgets/NComboBox.qml": ("NFieldBackground", "NMenuSurface", "NMenuItemBackground"),
            "Widgets/NSearchableComboBox.qml": ("NFieldBackground", "NMenuSurface", "NMenuItemBackground"),
            "Widgets/NContextMenu.qml": ("NMenuSurface", "NMenuItemBackground"),
            "Widgets/NPopupContextMenu.qml": ("NMenuSurface", "NMenuItemBackground"),
        }
        for widget, components in shared.items():
            source = (ROOT / widget).read_text()
            for component in components:
                self.assertIn(component + " {", source, widget)
            self.assertNotIn("Color.mHover", source, widget)

    def test_fields_keep_uniform_corners_and_use_focus_outline(self):
        source = (ROOT / "Widgets/NFieldBackground.qml").read_text()
        self.assertIn("Style.getFieldShape(active, cornerRadius)", source)
        self.assertIn("radius: fieldShape ? fieldShape.radius : cornerRadius", source)
        self.assertIn("fieldShape ? fieldShape.borderWidth", source)
        self.assertNotIn("bottomLeftRadius", source)
        self.assertNotIn("anchors.bottom", source)

    def test_settings_sidebar_reserves_scrollbar_space(self):
        source = (ROOT / "Modules/Panels/Settings/SettingsContent.qml").read_text()
        sidebar = source[source.index("id: sidebarList"):]
        sidebar = sidebar[:sidebar.index("id: tabItem") + 100]
        self.assertIn("reserveScrollbarSpace: root.material && verticalScrollBarActive", sidebar)
        self.assertIn("width: sidebarList.availableWidth", sidebar)
        self.assertIn("sidebarList.verticalScrollBarActive ? sidebarList.handleWidth + Style.marginXS : 0", source)
        self.assertIn("width: searchResultsList.availableWidth", source)

    def test_tonal_container_is_translucent(self):
        source = (ROOT / "Commons/Color.qml").read_text()
        self.assertIn("mTonalContainer: Qt.alpha(mOnSurface,", source)


    def test_header_pills_pad_evenly(self):
        # NPill sizes its width from its height so the padding is equal on
        # every side; header pills use it instead of their own Rectangle.
        pill = (ROOT / "Widgets/NPill.qml").read_text()
        self.assertIn("implicitWidth: row.implicitWidth + height - row.implicitHeight", pill)
        self.assertIn("anchors.centerIn: parent", pill)
        for header, count in (("Modules/Panels/ControlCenter/MaterialControlHeader.qml", 2),
                              ("Modules/Panels/KdeConnect/MaterialKdeConnectHome.qml", 1)):
            source = (ROOT / header).read_text()
            self.assertEqual(count, source.count("NPill {"), header)
            self.assertNotIn("radius: height / 2", source, header)

    def test_desktop_widgets_are_not_frosted(self):
        # They have no blur behind them and draw their shadow under the background.
        source = (ROOT / "Modules/DesktopWidgets/DraggableDesktopWidget.qml").read_text()
        self.assertNotIn("Style.panelOpacity", source)


class ComboSelectionTests(unittest.TestCase):
    def test_selected_is_emitted_last(self):
        # Selecting can rebuild the model and destroy the clicked delegate, so the
        # handler must not touch delegate-scoped ids after emitting selected().
        for widget in ("Widgets/NComboBox.qml", "Widgets/NSearchableComboBox.qml"):
            source = (ROOT / widget).read_text()
            handler = source[source.index("onClicked: {", source.index("delegate")):]
            handler = handler[:handler.index("\n              }\n")]
            after = handler[handler.index(".selected("):]
            self.assertNotIn("listView", after, widget)
            self.assertNotIn("popup.close", after, widget)


    def test_media_output_pill_centers_vertically(self):
        # Fill + uniform margins left the row shorter than its text, so it sat low in the pill.
        source = (ROOT / "Modules/Cards/MaterialMediaCard.qml").read_text()
        block = source[source.index("id: outputLabel"):]
        block = block[:block.index("NIcon {")]
        self.assertIn("anchors.verticalCenter: parent.verticalCenter", block)
        self.assertNotIn("anchors.fill", block)


class SettingsWindowBlurTests(unittest.TestCase):
    def test_settings_window_requests_blur(self):
        # The compositor leaves a translucent window unblurred unless it asks
        # for a blur region, which made frosted glass look plain see-through.
        source = (ROOT / "Modules/Panels/Settings/SettingsPanelWindow.qml").read_text()
        self.assertIn("BackgroundEffect.blurRegion: Settings.data.general.enableBlurBehind ? windowBlurRegion : null", source)
        region = source[source.index("id: windowBlurRegion"):]
        self.assertIn("width: root.width", region)
        self.assertIn("height: root.height", region)


if __name__ == "__main__":
    unittest.main()
