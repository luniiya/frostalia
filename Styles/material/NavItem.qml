import QtQuick
import qs.Commons
import qs.Widgets

// NNavItem: a tonal pill under the selected row, a state layer for hover and press.
Rectangle {
  id: root

  property Item control

  radius: control.radius
  color: control.selected ? Qt.tint(ShellColors.mSurfaceVariant, Qt.alpha(ShellColors.mSecondary, 0.22)) : "transparent"

  Behavior on color {
    enabled: !ShellColors.isTransitioning
    ColorAnimation {
      duration: Style.animationFast
      easing.type: Easing.InOutQuad
    }
  }

  NMaterialStateLayer {
    hovered: root.control.hovered
    pressed: root.control.pressed
    tint: ShellColors.mOnSurface
  }
}
