import QtQuick
import qs.Commons

// NDivider: a groove cut into the plate, a dark line with the light catching
// its lower lip.
Item {
  id: root

  property Item control
  readonly property var kit: Style.kitFor("Styles/keycap/Kit.qml")
  readonly property real line: Math.max(1, Math.round(kit.outline / 2))
  readonly property real thickness: line * 2

  Rectangle {
    width: root.control.vertical ? root.line : root.width
    height: root.control.vertical ? root.height : root.line
    radius: root.line / 2
    color: Qt.alpha(root.kit.ink, 0.4)
  }

  Rectangle {
    x: root.control.vertical ? root.line : 0
    y: root.control.vertical ? 0 : root.line
    width: root.control.vertical ? root.line : root.width
    height: root.control.vertical ? root.height : root.line
    radius: root.line / 2
    color: root.kit.ringFor(ShellColors.mSurface)
  }
}
