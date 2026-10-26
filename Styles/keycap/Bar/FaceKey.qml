import QtQuick
import ".." as Keycap

// A keycap filling its face, wired to the face's state and kit.
Keycap.Key {
  id: key

  required property var face

  width: parent ? parent.width : 0
  height: parent ? parent.height : 0
  y: face.centerShift
  scale: face.pop
  fillColor: face.kit.fill
  inkColor: face.kit.ink
  ringColor: face.kit.ringFor(fillColor)
  radius: Math.min(face.kit.radius, height / 2)
  outlineWidth: face.kit.outline
  ringWidth: face.kit.ring
  depth: face.depth
  pressedDepth: Math.min(face.kit.pressedDepth, face.depth)
  hoverLift: face.kit.hoverLift
  pressed: face.pressed
  hovered: face.hovered
  duration: face.kit.fast
  overshoot: face.kit.overshoot
}
