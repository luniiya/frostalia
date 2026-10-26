import QtQuick
import qs.Commons
import qs.Widgets

// Card behind each weather element.
// Material: borderless tonal container with large corners. Keycap: the same shape as an
// opaque keycap card. Caelestia: the NBox look.
Rectangle {
  readonly property var tokens: Style.uiStyleTokens.weather
  property bool tile: false

  radius: tokens ? (tile ? tokens.tileRadius : tokens.radius) : Style.radiusM
  color: Style.keycapControls ? Qt.tint(ShellColors.mSurfaceVariant, ShellColors.mTonalContainer) : (tokens ? ShellColors.mTonalContainer : ShellColors.smartAlpha(ShellColors.mSurfaceVariant))
  border.color: Style.boxBorderColor
  border.width: tokens ? 0 : Style.boxBorderWidth

  NKeycapCard {}
}
