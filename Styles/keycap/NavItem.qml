import QtQuick
import qs.Commons

// NNavItem: rows rest flat on the rail. Hovering one pops a key up out of it,
// pressing pushes the key down, and the selected row stays pushed under the
// plate with the wall's shade inside it, like the active workspace.
Item {
  id: root

  property Item control
  readonly property var kit: Style.kitFor("Styles/keycap/Kit.qml")
  readonly property bool shown: control.selected || control.hovered || control.pressed

  // Content offset from the row's center: the face is `depth` shorter and sinks
  readonly property real sink: key.sink - key.depth / 2

  Key {
    id: key
    width: root.width
    height: Math.max(0, root.height - depth)
    opacity: root.shown ? 1 : 0
    readonly property color baseFill: root.control.selected ? Qt.tint(ShellColors.mSurfaceVariant, Qt.alpha(ShellColors.mSecondary, 0.22)) : ShellColors.mSurface
    fillColor: baseFill
    inkColor: root.kit.ink
    ringColor: root.kit.ringFor(baseFill)
    radius: Math.min(root.control.radius, height / 2)
    outlineWidth: root.kit.outline
    // A sunken face catches no light on its rim
    ringWidth: root.control.selected ? 0 : root.kit.ring
    depth: root.kit.depth
    pressedDepth: root.control.selected ? 0 : root.kit.pressedDepth
    hoverLift: root.kit.hoverLift
    pressed: root.control.pressed
    latched: root.control.selected
    hovered: root.control.hovered
    duration: Style.animationFast
    overshoot: root.kit.overshoot

    Behavior on opacity {
      NumberAnimation {
        duration: Style.animationFast
      }
    }

    // The plate's edge shading the sunken face
    SunkenShade {
      kit: root.kit
      depth: key.depth + 1
      color: Qt.alpha(root.kit.ink, 0.45)
      fillColor: key.face.color
      topLeftRadius: key.radius
      topRightRadius: key.radius
      bottomLeftRadius: key.radius
      bottomRightRadius: key.radius
      opacity: root.control.selected ? 1 : 0

      Behavior on opacity {
        NumberAnimation {
          duration: Style.animationFast
        }
      }
    }
  }
}
