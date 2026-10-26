import QtQuick
import qs.Commons

// Shared background for dropdown and context menus: an opaque, slightly raised
// surface without an outline, dressed by the style's Card skin.
Rectangle {
  readonly property var menu: Style.uiStyleTokens.menu

  color: Qt.tint(ShellColors.mSurface, Qt.alpha(ShellColors.mOnSurface, 0.05))
  border.color: ShellColors.mOutline
  border.width: 0
  radius: menu.radius

  NStyleCard {}
}
