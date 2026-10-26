import QtQuick
import qs.Commons

// Shared background for dropdown and context menu items: pill items, the chosen
// one filled with primary and hover as a light tint.
Rectangle {
  id: root

  property bool highlighted: false
  property bool selected: false

  readonly property color contentColor: selected ? ShellColors.mOnPrimary : ShellColors.mOnSurface

  radius: height / 2
  color: {
    if (selected)
      return ShellColors.mPrimary;
    return highlighted ? ShellColors.mTonalContainer : "transparent";
  }

  Behavior on color {
    ColorAnimation {
      duration: Style.animationFast
    }
  }
}
