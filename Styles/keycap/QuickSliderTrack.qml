import QtQuick
import qs.Commons

// NMaterialQuickSlider track: one outlined keycap track filled up to an ink edge.
Rectangle {
  id: root

  property Item control
  readonly property var kit: Style.kitFor("Styles/keycap/Kit.qml")

  radius: Math.min(Style.iRadiusS, height / 2)
  color: ShellColors.mSurface

  Card {}

  // Fill, clipped to the inside of the outline
  Item {
    anchors.fill: parent
    anchors.margins: root.kit.outline
    clip: true
    Rectangle {
      readonly property real fillWidth: Math.max(0, Math.min(parent.width, root.control.visualPosition * parent.width))
      x: root.control.mirrored ? parent.width - fillWidth : 0
      width: fillWidth
      height: parent.height
      radius: Math.max(0, root.radius - root.kit.outline)
      color: root.control.enabled ? root.control.fillColor : ShellColors.mOutline
      visible: fillWidth > 0
      // Ink edge where the fill ends
      Rectangle {
        x: root.control.mirrored ? 0 : parent.width - width
        width: root.kit.outline
        height: parent.height
        color: root.kit.ink
        visible: parent.width < root.width - 2 * root.kit.outline
      }
    }
  }
}
