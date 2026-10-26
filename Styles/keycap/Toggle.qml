import QtQuick
import qs.Commons

// NToggle: outlined track; the handle is a small key with a hard shadow that sinks
// while pressed and springs across.
Rectangle {
  id: root

  property Item control
  readonly property var kit: Style.kitFor("Styles/keycap/Kit.qml")

  radius: Math.min(Style.iRadiusL, height / 2)
  color: control.checked ? ShellColors.mPrimary : ShellColors.mSurface
  border.color: kit.ink
  border.width: kit.outline

  Behavior on color {
    ColorAnimation {
      duration: Style.animationFast
    }
  }

  Behavior on border.color {
    ColorAnimation {
      duration: Style.animationFast
    }
  }

  Rectangle {
    width: handle.width
    height: handle.height
    radius: handle.radius
    x: handle.x
    y: handle.y - handle.anchors.verticalCenterOffset + Math.max(1, Math.round(root.kit.depth * 0.67))
    color: root.kit.ink
  }

  Rectangle {
    id: handle
    implicitWidth: root.control.geometry.handle
    implicitHeight: root.control.geometry.handle
    radius: Math.min(Style.iRadiusL, height / 2)
    color: root.control.checked ? ShellColors.mOnPrimary : ShellColors.mSurfaceVariant
    border.color: root.kit.ink
    border.width: root.kit.outline
    anchors.verticalCenter: parent.verticalCenter
    anchors.verticalCenterOffset: root.control.pressed ? Math.round(root.kit.depth * 0.5) : 0
    x: root.control.geometry.x

    Behavior on anchors.verticalCenterOffset {
      NumberAnimation {
        duration: Style.animationFaster
        easing.type: Easing.OutBack
        easing.overshoot: root.kit.overshoot
      }
    }

    Behavior on x {
      NumberAnimation {
        duration: Style.animationNormal
        easing.type: Easing.OutBack
        easing.overshoot: root.kit.popOvershoot
      }
    }
  }
}
