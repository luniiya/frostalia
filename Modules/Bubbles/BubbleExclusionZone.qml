import QtQuick
import Quickshell
import Quickshell.Wayland

// Invisible window that keeps windows clear of the bubbles on one screen edge.
PanelWindow {
  id: root

  required property string edge
  required property real size

  readonly property bool vertical: edge === "left" || edge === "right"

  visible: size > 0
  color: "transparent"
  mask: Region {}

  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.namespace: "frostalia-bubble-exclusion-" + (screen?.name || "unknown") + "-" + edge
  WlrLayershell.exclusionMode: ExclusionMode.Auto

  anchors {
    top: edge !== "bottom"
    bottom: edge !== "top"
    left: edge !== "right"
    right: edge !== "left"
  }

  implicitWidth: vertical ? size : 0
  implicitHeight: vertical ? 0 : size
}
