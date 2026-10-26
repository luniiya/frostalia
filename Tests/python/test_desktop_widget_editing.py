"""Desktop editing wires live sizing feedback and shared undo/redo to all layouts."""
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]


class DesktopWidgetEditingTests(unittest.TestCase):
    def test_scale_is_snapped_before_it_is_saved_and_cancel_restores_it(self):
        source = (ROOT / "Modules/DesktopWidgets/DraggableDesktopWidget.qml").read_text()
        resize = source[source.index("id: scaleMouseArea"):]
        release = resize[resize.index("onReleased:"):resize.index("onCanceled:")]
        self.assertLess(release.index("root.snapScaleToGrid"), release.index("root.updateWidgetData"))
        self.assertIn("Qt.ShiftModifier", resize)
        self.assertIn("root.widgetScale = internal.initialScale", resize[resize.index("onCanceled:"):])
        self.assertIn("WidgetEdit.snappedScale", source)

    def test_size_feedback_reports_multiplier_and_actual_dimensions(self):
        source = (ROOT / "Modules/DesktopWidgets/DraggableDesktopWidget.qml").read_text()
        self.assertIn("WidgetEdit.scaleText(root.widgetScale * (root.horizontalResizable ? root.widgetWidthScale : 1))", source)
        self.assertIn("WidgetEdit.scaleText(root.widgetScale * (root.verticalResizable ? root.widgetHeightScale : 1))", source)
        self.assertIn('"width": Math.round(root.width)', source)
        self.assertIn('"height": Math.round(root.height)', source)
        self.assertIn("WidgetEdit.feedbackPosition", source)

    def test_history_observes_all_layout_changes_without_recording_restores(self):
        source = (ROOT / "Services/UI/DesktopWidgetRegistry.qml").read_text()
        self.assertIn("function onMonitorWidgetsChanged()", source)
        self.assertIn("root.recordLayout()", source)
        self.assertIn("!historyReady || restoringLayout || !Settings.isLoaded", source)
        self.assertIn("function onSettingsLoaded()", source)
        self.assertIn("Settings.data.desktopWidgets.monitorWidgets = WidgetHistory.snapshot(next.current)", source)
        self.assertIn("currentSettingsDialog.flushPendingChanges()", source)
        self.assertIn("currentSettingsDialog.discardPendingChanges()", source)
        self.assertIn("!manipulatingWidget", source)

    def test_history_controls_and_shortcuts_are_available_in_both_editors(self):
        for name in ("Modules/EditDesktop/EditDesktopWindow.qml", "Modules/Panels/Settings/Tabs/DesktopWidgetsTab.qml"):
            source = (ROOT / name).read_text()
            with self.subTest(path=name):
                self.assertIn('sequence: "Ctrl+Z"', source)
                self.assertIn('sequences: ["Ctrl+Shift+Z", "Ctrl+Y"]', source)
                self.assertIn("enabled: DesktopWidgetRegistry.canUndo", source)
                self.assertIn("enabled: DesktopWidgetRegistry.canRedo", source)
                self.assertIn("DesktopWidgetRegistry.undo()", source)
                self.assertIn("DesktopWidgetRegistry.redo()", source)

    def test_axis_capabilities_and_system_monitor_layout(self):
        capabilities = {
            "Clock": (False, False), "MediaPlayer": (True, False),
            "Weather": (True, False), "WeatherDetails": (True, False),
            "SystemStat": (True, True), "AudioVisualizer": (True, True),
        }
        for widget, axes in capabilities.items():
            source = (ROOT / f"Modules/DesktopWidgets/Widgets/Desktop{widget}.qml").read_text()
            with self.subTest(widget=widget):
                for axis, enabled in zip(("horizontal", "vertical"), axes):
                    self.assertIn(f"{axis}Resizable: {str(enabled).lower()}", source)
                self.assertNotIn("  width: implicitWidth", source)
                self.assertNotIn("  height: implicitHeight", source)
        monitor = (ROOT / "Modules/DesktopWidgets/Widgets/DesktopSystemStat.qml").read_text()
        self.assertIn("minimumWidgetWidth:", monitor)
        self.assertIn("minimumWidgetHeight:", monitor)
        self.assertEqual(monitor.count("sourceComponent: graphComponent"), 2)
        self.assertGreaterEqual(monitor.count("Layout.fillHeight: true"), 2)
        self.assertGreaterEqual(monitor.count("Layout.fillWidth: true"), 2)

    def test_edge_resize_persists_one_transaction_and_cancel_restores_both_axes(self):
        source = (ROOT / "Modules/DesktopWidgets/DraggableDesktopWidget.qml").read_text()
        edge = source[source.index("id: edgeHandle"):]
        self.assertIn("root.horizontalResizable : root.verticalResizable", edge)
        self.assertIn("WidgetEdit.resizedAxis", edge)
        release = edge[edge.index("onReleased:"):edge.index("onCanceled:")]
        self.assertEqual(release.count("root.updateWidgetData"), 1)
        self.assertIn("widthScale: root.widgetWidthScale", release)
        self.assertIn("heightScale: root.widgetHeightScale", release)
        cancel = edge[edge.index("onCanceled:"):]
        self.assertIn("root.widgetWidthScale = internal.initialWidthScale", cancel)
        self.assertIn("root.widgetHeightScale = internal.initialHeightScale", cancel)
        self.assertNotIn("updateWidgetData", cancel)
        self.assertIn('"widthScale": 1.0', source)
        self.assertIn('"heightScale": 1.0', source)
