import QtQuick
import qs.Commons

// Material interaction feedback follows the containing control's shape. Shown only
// in styles that use state layers (token `stateLayers`).
Rectangle {
  id: root
  property bool hovered: false
  property bool pressed: false
  property color tint: ShellColors.mPrimary
  anchors.fill: parent
  radius: parent.radius
  visible: Style.uiStyleTokens.stateLayers
  color: tint
  opacity: pressed ? 0.12 : hovered ? 0.08 : 0

  Behavior on opacity {
    NumberAnimation {
      duration: Style.animationFast
      easing.type: Easing.OutCubic
    }
  }
}
