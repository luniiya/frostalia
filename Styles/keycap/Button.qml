import QtQuick
import qs.Commons

// NButton: a filled key with a hard shadow that sinks while pressed. Outlined
// buttons become surface keys with the accent as content color.
Key {
  id: root

  property Item control
  readonly property var kit: Style.kitFor("Styles/keycap/Kit.qml")

  readonly property color contentColor: !control.enabled ? ShellColors.mOnSurfaceVariant : (control.outlined ? control.backgroundColor : control.textColor)
  readonly property real controlScale: 1
  // Translucent colors (tonal buttons) are flattened onto the surface: a see-through
  // keycap shows its ink shadow through the face
  readonly property color baseFill: Qt.tint(ShellColors.mSurface, !control.enabled ? ShellColors.mSurfaceVariant : (control.outlined ? ShellColors.mSurface : control.backgroundColor))

  fillColor: control.hovered && control.enabled && !control.outlined ? Qt.lighter(baseFill, 1.08) : baseFill
  inkColor: kit.ink
  ringColor: kit.ringFor(baseFill)
  radius: control.buttonRadius
  outlineWidth: kit.outline
  ringWidth: kit.ring
  depth: kit.depth
  pressedDepth: kit.pressedDepth
  hoverLift: kit.hoverLift
  pressed: control.pressed
  hovered: control.hovered && control.enabled
  duration: Style.animationFast
  overshoot: kit.overshoot
}
