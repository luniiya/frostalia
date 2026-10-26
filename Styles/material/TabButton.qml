import QtQuick
import qs.Commons
import qs.Widgets

// NTabButton: one button of a Material connected button group. The selected
// button is fully rounded, inner corners stay small.
Rectangle {
  id: root

  property Item control

  readonly property color contentColor: control.checked ? ShellColors.mOnPrimary : ShellColors.mOnSurface
  property real leftRadius: control.groupLeftRadius
  property real rightRadius: control.groupRightRadius

  topLeftRadius: leftRadius
  bottomLeftRadius: leftRadius
  topRightRadius: rightRadius
  bottomRightRadius: rightRadius
  color: control.checked ? ShellColors.mPrimary : ShellColors.mTonalContainer

  Behavior on leftRadius {
    NumberAnimation {
      duration: Style.animationFast
      easing.type: Easing.OutCubic
    }
  }
  Behavior on rightRadius {
    NumberAnimation {
      duration: Style.animationFast
      easing.type: Easing.OutCubic
    }
  }

  Behavior on color {
    enabled: !ShellColors.isTransitioning
    ColorAnimation {
      duration: Style.animationFast
      easing.type: Easing.OutCubic
    }
  }

  NMaterialStateLayer {
    topLeftRadius: root.leftRadius
    bottomLeftRadius: root.leftRadius
    topRightRadius: root.rightRadius
    bottomRightRadius: root.rightRadius
    hovered: root.control.isHovered
    pressed: root.control.pressed
    tint: root.control.checked ? ShellColors.mOnPrimary : ShellColors.mPrimary
  }
}
