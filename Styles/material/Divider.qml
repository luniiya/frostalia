import QtQuick
import qs.Commons

// NDivider: a solid, soft hairline in the outline color, end to end.
Rectangle {
  property Item control

  readonly property real thickness: Style.borderS

  radius: thickness / 2
  color: Qt.alpha(ShellColors.mOutline, 0.6)
}
