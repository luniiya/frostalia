import QtQuick
import qs.Commons
import qs.Widgets

// NIconButton: filled tonal icon button that stays visible on surface-variant pages.
Rectangle {
  id: root

  property Item control

  readonly property color defaultBackground: ShellColors.mTonalContainer

  color: control.color
  radius: control.radius
  border.color: control.border.color
  border.width: control.border.width

  Behavior on color {
    enabled: !ShellColors.isTransitioning
    ColorAnimation {
      duration: Style.animationFast
      easing.type: Easing.InOutQuad
    }
  }

  NMaterialStateLayer {
    hovered: root.control.hovering
    pressed: root.control.pressed
    tint: root.control.colorFg
  }

  NIcon {
    icon: root.control.icon
    pointSize: Style.toOdd(root.width * 0.48)
    applyUiScale: root.control.applyUiScale
    color: root.control.enabled && root.control.hovering ? root.control.colorFgHover : root.control.colorFg
    // Pixel-perfect centering
    x: Style.pixelAlignCenter(root.width, width)
    y: Style.pixelAlignCenter(root.height, contentHeight)

    Behavior on color {
      enabled: !ShellColors.isTransitioning
      ColorAnimation {
        duration: Style.animationFast
        easing.type: Easing.InOutQuad
      }
    }
  }
}
