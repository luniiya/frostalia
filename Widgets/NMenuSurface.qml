import QtQuick
import qs.Commons

// Shared background for dropdown and context menus.
// Material: opaque, slightly raised surface without an outline.
Rectangle {
  property color fallbackColor: ShellColors.mSurfaceVariant
  property real fallbackRadius: Style.iRadiusM

  readonly property var menu: Style.uiStyleTokens.menu

  color: menu ? Qt.tint(ShellColors.mSurface, Qt.alpha(ShellColors.mOnSurface, 0.05)) : fallbackColor
  border.color: ShellColors.mOutline
  border.width: menu ? 0 : Style.borderS
  radius: menu ? menu.radius : fallbackRadius
}
