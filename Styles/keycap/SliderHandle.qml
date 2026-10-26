import QtQuick
import qs.Commons

// NSlider handle: a round key on a hard shadow; it sinks into the shadow while pressed.
Item {
  id: root

  property Item control
  readonly property var kit: Style.kitFor("Styles/keycap/Kit.qml")

  Rectangle {
    width: knob.width
    height: knob.height
    radius: knob.radius
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2 + root.kit.depth
    color: root.kit.ink
  }

  Rectangle {
    id: knob
    anchors.centerIn: parent
    anchors.verticalCenterOffset: root.control.pressed ? root.kit.depth - root.kit.pressedDepth : 0
    implicitWidth: root.control.knobDiameter
    implicitHeight: root.control.knobDiameter
    radius: Math.min(Style.iRadiusL, width / 2)
    color: root.control.effectiveFillColor
    border.color: root.kit.ink
    border.width: root.kit.outline

    // Cream ring just inside the outline
    Rectangle {
      anchors.fill: parent
      anchors.margins: root.kit.outline
      radius: Math.max(0, parent.radius - root.kit.outline)
      color: "transparent"
      border.color: root.kit.ringFor(root.control.effectiveFillColor)
      border.width: root.kit.ring
    }

    Behavior on anchors.verticalCenterOffset {
      NumberAnimation {
        duration: root.control.pressed ? Style.animationFaster : Style.animationFast
        easing.type: root.control.pressed ? Easing.OutQuad : Easing.OutBack
        easing.overshoot: root.kit.overshoot
      }
    }

    Behavior on color {
      ColorAnimation {
        duration: Style.animationFast
      }
    }
  }
}
