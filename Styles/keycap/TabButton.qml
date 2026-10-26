import QtQuick
import qs.Commons

// NTabButton: outlined segment that fills with the hover color under the pointer.
Rectangle {
  id: root

  property Item control

  readonly property color contentColor: control.isHovered ? ShellColors.mOnHover : (control.checked ? ShellColors.mOnPrimary : ShellColors.mOnSurface)

  topLeftRadius: control.groupLeftRadius
  bottomLeftRadius: control.groupLeftRadius
  topRightRadius: control.groupRightRadius
  bottomRightRadius: control.groupRightRadius
  color: control.isHovered ? ShellColors.mHover : (control.checked ? ShellColors.mPrimary : ShellColors.smartAlpha(ShellColors.mSurface))
  border.color: control.checked ? ShellColors.mPrimary : ShellColors.mOutline
  border.width: Style.borderS

  Behavior on color {
    enabled: !ShellColors.isTransitioning
    ColorAnimation {
      duration: Style.animationFast
      easing.type: Easing.OutCubic
    }
  }
}
