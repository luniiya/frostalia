import QtQuick
import qs.Commons
import qs.Widgets

// NButton: filled button; outlined buttons become tonal buttons (tinted pill, no
// border). The button shrinks a little while pressed.
Rectangle {
  id: root

  property Item control

  readonly property bool tonal: control.outlined
  readonly property color contentColor: {
    if (!control.enabled)
      return ShellColors.mOnSurfaceVariant;
    if (control.hovered)
      return control.textHoverColor;
    if (tonal)
      return ShellColors.mOnSurface;
    return control.textColor;
  }
  readonly property real sink: 0
  readonly property real controlScale: control.pressed ? 0.97 : 1

  radius: control.buttonRadius
  color: {
    if (!control.enabled)
      return control.outlined ? "transparent" : Qt.lighter(ShellColors.mSurfaceVariant, 1.2);
    if (control.hovered)
      return control.hoverColor;
    if (tonal)
      return Qt.alpha(control.backgroundColor, 0.16);
    return control.backgroundColor;
  }

  Behavior on color {
    enabled: !ShellColors.isTransitioning
    ColorAnimation {
      duration: Style.animationFast
      easing.type: Easing.OutCubic
    }
  }

  NMaterialStateLayer {
    hovered: root.control.hovered
    pressed: root.control.pressed
    tint: root.tonal ? ShellColors.mOnSurface : root.control.textColor
  }
}
