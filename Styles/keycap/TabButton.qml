import QtQuick
import qs.Commons

// NTabButton: every segment is a raised key. Pressing one pushes it down, and the
// selected segment stays pushed under the plate, its top wall casting a shade
// inside it, in the accent color until another one takes over. The face leaves room for its shadow inside the control.
Item {
  id: root

  property Item control
  readonly property var kit: Style.kitFor("Styles/keycap/Kit.qml")

  readonly property color contentColor: control.checked ? kit.readableOn(kit.primary) : ShellColors.mOnSurface
  // Content offset from the control's center: the face is `depth` shorter and sinks
  readonly property real sink: key.sink - key.depth / 2

  Key {
    id: key
    width: root.width
    height: Math.max(0, root.height - depth)
    readonly property color baseFill: root.control.checked ? root.kit.primary : ShellColors.mSurface
    fillColor: root.control.isHovered && !root.control.checked ? Qt.lighter(baseFill, 1.08) : baseFill
    inkColor: root.kit.ink
    ringColor: root.kit.ringFor(baseFill)
    topLeftRadius: root.control.groupLeftRadius
    bottomLeftRadius: root.control.groupLeftRadius
    topRightRadius: root.control.groupRightRadius
    bottomRightRadius: root.control.groupRightRadius
    outlineWidth: root.kit.outline
    // A sunken face catches no light on its rim
    ringWidth: root.control.checked ? 0 : root.kit.ring
    depth: root.kit.depth
    // Held down by the pointer: part way; selected: all the way, and it stays
    pressedDepth: root.control.checked ? 0 : root.kit.pressedDepth
    hoverLift: root.kit.hoverLift
    pressed: root.control.pressed
    latched: root.control.checked
    hovered: root.control.isHovered
    duration: Style.animationFast
    overshoot: root.kit.overshoot

    // The plate's edge shading the sunken face
    SunkenShade {
      kit: root.kit
      depth: key.depth + 1
      color: Qt.alpha(root.kit.ink, 0.45)
      fillColor: key.face.color
      topLeftRadius: root.control.groupLeftRadius
      topRightRadius: root.control.groupRightRadius
      bottomLeftRadius: root.control.groupLeftRadius
      bottomRightRadius: root.control.groupRightRadius
      opacity: root.control.checked ? 1 : 0

      Behavior on opacity {
        NumberAnimation {
          duration: Style.animationFast
        }
      }
    }
  }
}
