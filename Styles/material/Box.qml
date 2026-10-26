import QtQuick
import qs.Commons

// NBox: a filled rounded container, translucent with the panel opacity.
Rectangle {
  property Item control

  readonly property color defaultBorderColor: Style.boxBorderColor

  radius: control.radius
  border.color: control.border.color
  border.width: control.border.width
  color: control.forceOpaque ? control.color : ShellColors.smartAlpha(control.color)
}
