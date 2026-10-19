import QtQuick
import qs.Commons

// Shared background for dropdown and context menus.
// Material: opaque, slightly raised surface without an outline.
Rectangle {
  property color fallbackColor: Color.mSurfaceVariant
  property real fallbackRadius: Style.iRadiusM

  readonly property var menu: Style.uiStyleTokens.menu

  color: menu ? Qt.tint(Color.mSurface, Qt.alpha(Color.mOnSurface, 0.05)) : fallbackColor
  border.color: Color.mOutline
  border.width: menu ? 0 : Style.borderS
  radius: menu ? menu.radius : fallbackRadius
}
