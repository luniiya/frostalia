import QtQuick
import qs.Commons

// NSlider handle: a slim vertical bar that narrows while pressed.
Item {
  id: root

  property Item control

  Rectangle {
    anchors.centerIn: parent
    implicitWidth: root.control.pressed ? root.control.sliderGeometry.pressedHandleWidth : root.control.sliderGeometry.handleWidth
    implicitHeight: root.control.sliderGeometry.handleHeight
    radius: Math.min(Style.iRadiusL, width / 2)
    color: root.control.effectiveFillColor

    Behavior on implicitWidth {
      NumberAnimation {
        duration: Style.animationFast
        easing.type: Easing.OutCubic
      }
    }

    Behavior on color {
      ColorAnimation {
        duration: Style.animationFast
      }
    }
  }
}
