import QtQuick
import qs.Commons

// NFieldBackground: rounded filled field with an outline on focus.
Rectangle {
  property Item control

  radius: control.radius
  color: control.fieldShape ? (control.hovered && !control.active ? Qt.alpha(ShellColors.mOnSurface, 0.12) : ShellColors.mTonalContainer) : control.fillColor
  border.color: control.active ? control.activeBorderColor : ShellColors.mOutline
  border.width: control.fieldShape ? control.fieldShape.borderWidth : (control.outlined ? Style.borderS : 0)

  Behavior on border.color {
    ColorAnimation {
      duration: Style.animationFast
    }
  }
}
