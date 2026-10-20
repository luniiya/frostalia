import QtQuick
import qs.Commons

// Card behind each weather element.
// Material: borderless tonal container with large corners. Caelestia: the NBox look.
Rectangle {
  readonly property var tokens: Style.uiStyleTokens.weather
  property bool tile: false

  radius: tokens ? (tile ? tokens.tileRadius : tokens.radius) : Style.radiusM
  color: tokens ? ShellColors.mTonalContainer : ShellColors.smartAlpha(ShellColors.mSurfaceVariant)
  border.color: Style.boxBorderColor
  border.width: tokens ? 0 : Style.boxBorderWidth
}
