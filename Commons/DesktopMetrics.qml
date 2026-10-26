pragma Singleton

import QtQuick
import "../Helpers/DesktopMetrics.js" as Metrics

// Style-independent sizes for desktop widgets, see Helpers/DesktopMetrics.js
QtObject {
  readonly property real fontSizeXXS: Metrics.fontSizes.XXS
  readonly property real fontSizeXS: Metrics.fontSizes.XS
  readonly property real fontSizeS: Metrics.fontSizes.S
  readonly property real fontSizeM: Metrics.fontSizes.M
  readonly property real fontSizeL: Metrics.fontSizes.L
  readonly property real fontSizeXL: Metrics.fontSizes.XL
  readonly property real fontSizeXXL: Metrics.fontSizes.XXL
  readonly property real fontSizeXXXL: Metrics.fontSizes.XXXL

  readonly property int marginXXXS: Metrics.margins.XXXS
  readonly property int marginXXS: Metrics.margins.XXS
  readonly property int marginXS: Metrics.margins.XS
  readonly property int marginS: Metrics.margins.S
  readonly property int marginM: Metrics.margins.M
  readonly property int marginL: Metrics.margins.L
  readonly property int marginXL: Metrics.margins.XL

  readonly property int margin2XXXS: marginXXXS * 2
  readonly property int margin2XXS: marginXXS * 2
  readonly property int margin2XS: marginXS * 2
  readonly property int margin2S: marginS * 2
  readonly property int margin2M: marginM * 2
  readonly property int margin2L: marginL * 2
  readonly property int margin2XL: marginXL * 2
}
