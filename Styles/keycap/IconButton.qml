import QtQuick
import qs.Commons
import qs.Widgets

// NIconButton: the button is a key that sinks while pressed.
Key {
  id: root

  property Item control
  readonly property var kit: Style.kitFor("Styles/keycap/Kit.qml")

  readonly property color defaultBackground: ShellColors.smartAlpha(ShellColors.mSurfaceVariant)
  // Translucent backgrounds are flattened onto the surface (forcing their alpha to 1
  // would turn a light tonal tint into a near-black key)
  readonly property color baseFill: control.colorBg.a > 0.05 ? Qt.tint(ShellColors.mSurface, control.colorBg) : kit.fill

  y: -Math.round(depth / 2)
  fillColor: baseFill
  inkColor: kit.ink
  ringColor: kit.ringFor(baseFill)
  radius: control.radius
  outlineWidth: kit.outline
  ringWidth: kit.ring
  depth: Math.min(control.faceDepth, kit.depth)
  pressedDepth: kit.pressedDepth
  hoverLift: kit.hoverLift
  pressed: control.pressed
  hovered: control.hovering
  duration: Style.animationFast
  overshoot: kit.overshoot

  NIcon {
    icon: root.control.icon
    pointSize: Style.toOdd(root.control.buttonSize * 0.48)
    applyUiScale: root.control.applyUiScale
    color: root.control.colorFg
    x: Style.pixelAlignCenter(parent.width, width)
    y: Style.pixelAlignCenter(parent.height, contentHeight)
  }
}
