import QtQuick
import qs.Commons

// NBox: boxes are cards with an ink outline, a cream ring and a hard shadow. A
// transparent box is only a layout container: no card, or its shadow shows as a slab.
// Cards are solid so their shadow does not show through.
Item {
  id: root

  property Item control
  readonly property var kit: Style.kitFor("Styles/keycap/Kit.qml")

  readonly property bool isCard: control.color.a > 0
  readonly property color defaultBorderColor: isCard && Settings.data.ui.boxBorderEnabled ? kit.ink : Style.boxBorderColor

  Rectangle {
    visible: root.isCard
    width: parent.width
    height: parent.height
    y: root.kit.depth
    radius: root.control.radius
    color: root.kit.ink
  }

  Rectangle {
    id: bg
    anchors.fill: parent
    radius: root.control.radius
    border.color: root.control.border.color
    border.width: root.control.border.width
    color: root.control.color

    Rectangle {
      visible: root.isCard && bg.border.width > 0
      anchors.fill: parent
      anchors.margins: bg.border.width
      radius: Math.max(0, bg.radius - bg.border.width)
      color: "transparent"
      border.color: root.kit.ringFor(bg.color)
      border.width: root.kit.ring
    }
  }
}
