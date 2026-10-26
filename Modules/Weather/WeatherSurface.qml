import QtQuick
import qs.Commons
import qs.Widgets

// Card behind each weather element: a borderless tonal container with large corners.
// Keycap draws the same shape as an opaque keycap card.
Rectangle {
  readonly property var tokens: Style.uiStyleTokens.weather
  property bool tile: false

  radius: tile ? tokens.tileRadius : tokens.radius
  color: Style.opaqueSurfaces ? Qt.tint(ShellColors.mSurfaceVariant, ShellColors.mTonalContainer) : ShellColors.mTonalContainer
  border.width: 0

  NStyleCard {}
}
