import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Modules.Cards
import qs.Modules.MainScreen
import qs.Services.Media
import qs.Services.UI
import qs.Widgets

SmartPanel {
  id: root

  // Positioning
  readonly property string controlCenterPosition: Settings.data.controlCenter.position

  // Check if there's a bar on this screen
  readonly property bool hasBarOnScreen: {
    var monitors = Settings.data.bar.monitors || [];
    return monitors.length === 0 || monitors.includes(screen?.name);
  }

  // When position is "close_to_bar_button" but there's no bar, fall back to center
  readonly property bool shouldCenter: controlCenterPosition === "close_to_bar_button" && !hasBarOnScreen

  panelAnchorHorizontalCenter: shouldCenter || (controlCenterPosition !== "close_to_bar_button" && (controlCenterPosition.endsWith("_center") || controlCenterPosition === "center"))
  panelAnchorVerticalCenter: shouldCenter || controlCenterPosition === "center"
  panelAnchorLeft: !shouldCenter && controlCenterPosition !== "close_to_bar_button" && controlCenterPosition.endsWith("_left")
  panelAnchorRight: !shouldCenter && controlCenterPosition !== "close_to_bar_button" && controlCenterPosition.endsWith("_right")
  panelAnchorBottom: !shouldCenter && controlCenterPosition !== "close_to_bar_button" && controlCenterPosition.startsWith("bottom_")
  panelAnchorTop: !shouldCenter && controlCenterPosition !== "close_to_bar_button" && controlCenterPosition.startsWith("top_")

  preferredWidth: Math.round(440 * Style.uiScaleRatio)
  preferredHeight: Math.round(900 * Style.uiScaleRatio)

  onOpened: {
    MediaService.autoSwitchingPaused = true;
  }
  onClosed: {
    MediaService.autoSwitchingPaused = false;
  }

  panelContent: Item {
    property real contentPreferredHeight: centerView.item?.implicitHeight || root.preferredHeight
    NStyleView {
      id: centerView
      anchors.fill: parent
      surface: "controlCenter"
      viewProperties: ({
                         screen: root.screen
                       })
    }
  }
}
