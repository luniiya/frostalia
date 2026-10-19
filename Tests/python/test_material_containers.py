"""Material filled controls must stay visible on surface-variant backgrounds (settings pages)."""
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]


class MaterialContainerTests(unittest.TestCase):
    def test_filled_controls_use_tonal_container(self):
        for widget in ("Widgets/NTabButton.qml", "Widgets/NCollapsible.qml", "Widgets/NIconButton.qml",
                       "Widgets/NTextInput.qml", "Widgets/NComboBox.qml"):
            source = (ROOT / widget).read_text()
            self.assertIn("Color.mTonalContainer", source, widget)
            self.assertNotIn("? Color.mSurfaceVariant", source, widget)

    def test_tonal_container_is_translucent(self):
        source = (ROOT / "Commons/Color.qml").read_text()
        self.assertIn("mTonalContainer: Qt.alpha(mOnSurface,", source)


    def test_desktop_widgets_are_not_frosted(self):
        # They have no blur behind them and draw their shadow under the background.
        source = (ROOT / "Modules/DesktopWidgets/DraggableDesktopWidget.qml").read_text()
        self.assertNotIn("Style.panelOpacity", source)


if __name__ == "__main__":
    unittest.main()
