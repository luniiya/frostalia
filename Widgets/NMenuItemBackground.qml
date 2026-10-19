import QtQuick
import qs.Commons

// Shared background for dropdown and context menu items.
// Material: pill items, the chosen one filled with primary and hover as a light tint.
// Other styles: hover color fill.
Rectangle {
  id: root

  property bool highlighted: false
  property bool selected: false
  property real fallbackRadius: Style.iRadiusS

  readonly property bool _material: Style.materialControls
  readonly property color contentColor: {
    if (_material && selected)
      return Color.mOnPrimary;
    if (!_material && highlighted)
      return Color.mOnHover;
    return Color.mOnSurface;
  }

  radius: _material ? height / 2 : fallbackRadius
  color: {
    if (!_material)
      return highlighted ? Color.mHover : "transparent";
    if (selected)
      return Color.mPrimary;
    return highlighted ? Color.mTonalContainer : "transparent";
  }

  Behavior on color {
    ColorAnimation {
      duration: Style.animationFast
    }
  }
}
