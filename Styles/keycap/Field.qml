import QtQuick
import qs.Commons

// NFieldBackground: ink outline on a short hard shadow. Fields are opaque so the
// shadow only shows under the bottom edge.
Rectangle {
  id: root

  property Item control
  readonly property var kit: Style.kitFor("Styles/keycap/Kit.qml")

  radius: control.radius
  color: control.hovered && !control.active ? Qt.tint(ShellColors.mSurface, Qt.alpha(ShellColors.mPrimary, 0.08)) : ShellColors.mSurface
  border.color: control.active ? ShellColors.mPrimary : kit.ink
  border.width: kit.outline

  Rectangle {
    z: -1
    width: parent.width
    height: parent.height
    y: Math.max(1, root.kit.depth - 1)
    radius: parent.radius
    color: root.kit.ink
  }

  Behavior on border.color {
    ColorAnimation {
      duration: Style.animationFast
    }
  }
}
