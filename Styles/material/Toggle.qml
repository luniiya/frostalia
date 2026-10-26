import QtQuick
import qs.Commons

// NToggle: Material switch. The handle grows when on and while pressed.
Rectangle {
  id: root

  property Item control

  radius: Math.min(Style.iRadiusL, height / 2)
  color: control.checked ? ShellColors.mPrimary : ShellColors.mSurfaceVariant
  border.color: control.checked ? ShellColors.mPrimary : ShellColors.mOutline
  border.width: Style.toggleStyle.border * control.baseSize / 26

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
    implicitWidth: root.control.geometry.handle
    implicitHeight: root.control.geometry.handle
    radius: Math.min(Style.iRadiusL, height / 2)
    color: root.control.checked ? ShellColors.mOnPrimary : ShellColors.mOutline
    anchors.verticalCenter: parent.verticalCenter
    x: root.control.geometry.x

    Behavior on implicitWidth {
      NumberAnimation {
        duration: Style.animationFast
        easing.type: Easing.OutCubic
      }
    }
    Behavior on implicitHeight {
      NumberAnimation {
        duration: Style.animationFast
        easing.type: Easing.OutCubic
      }
    }
    Behavior on x {
      NumberAnimation {
        duration: Style.animationFast
        easing.type: Easing.OutCubic
      }
    }
  }
}
