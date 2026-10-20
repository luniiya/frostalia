pragma Singleton

import QtQuick
import Quickshell
import "../Helpers/BubbleLogic.js" as BubbleLogic
import "../Helpers/NotchGeometry.js" as NotchGeometry
import "../Helpers/OutlineStyle.js" as OutlineStyle
import "../Helpers/UiStyles.js" as UiStyles
import qs.Services.Power

Singleton {
  id: root

  // Register the preset fonts before shared widgets resolve their families.
  property FontLoader caelestiaFont: FontLoader {
    source: Qt.resolvedUrl("../Assets/Fonts/rubik/Rubik.ttf")
  }
  property FontLoader materialFont: FontLoader {
    source: Qt.resolvedUrl("../Assets/Fonts/roboto/Roboto.ttf")
  }

  readonly property string uiStyleId: UiStyles.resolveId(Settings.data.ui.style)
  readonly property var uiStyleChoices: UiStyles.choices()
  readonly property var uiStyleTokens: UiStyles.tokens(uiStyleId)
  readonly property bool materialControls: uiStyleTokens.controls.renderer === "material"
  readonly property var sliderStyle: uiStyleTokens.slider
  readonly property var toggleStyle: uiStyleTokens.toggle
  readonly property string fontDefault: UiStyles.fontFamily(uiStyleId, Settings.data.ui.fontDefault, false, Qt.application.font.family)
  readonly property string fontFixed: UiStyles.fontFamily(uiStyleId, Settings.data.ui.fontFixed, true, Qt.application.font.family)

  function surfaceUrl(surface) {
    const path = UiStyles.view(uiStyleId, surface);
    return path ? Quickshell.shellDir + "/" + path : "";
  }

  function getSliderGeometry(heightRatio) {
    return UiStyles.sliderGeometry(uiStyleId, baseWidgetSize, heightRatio, uiScaleRatio);
  }

  function getToggleGeometry(baseSize, checked, pressed) {
    return UiStyles.toggleGeometry(uiStyleId, baseSize, checked, pressed);
  }

  function splitSliderTrack(width, hitWidth, position, gap, mirrored) {
    return UiStyles.splitSliderTrack(width, hitWidth, position, gap, mirrored);
  }

  // Font size
  readonly property real fontSizeXXS: uiStyleTokens.fontSizes.XXS
  readonly property real fontSizeXS: uiStyleTokens.fontSizes.XS
  readonly property real fontSizeS: uiStyleTokens.fontSizes.S
  readonly property real fontSizeM: uiStyleTokens.fontSizes.M
  readonly property real fontSizeL: uiStyleTokens.fontSizes.L
  readonly property real fontSizeXL: uiStyleTokens.fontSizes.XL
  readonly property real fontSizeXXL: uiStyleTokens.fontSizes.XXL
  readonly property real fontSizeXXXL: uiStyleTokens.fontSizes.XXXL

  // Font weight
  readonly property int fontWeightRegular: uiStyleTokens.fontWeights.Regular
  readonly property int fontWeightMedium: uiStyleTokens.fontWeights.Medium
  readonly property int fontWeightSemiBold: uiStyleTokens.fontWeights.SemiBold
  readonly property int fontWeightBold: uiStyleTokens.fontWeights.Bold

  // Container Radii: major layout sections (sidebars, cards, content panels)
  readonly property int radiusXXXS: Math.round(uiStyleTokens.radii.XXXS * Settings.data.general.radiusRatio)
  readonly property int radiusXXS: Math.round(uiStyleTokens.radii.XXS * Settings.data.general.radiusRatio)
  readonly property int radiusXS: Math.round(uiStyleTokens.radii.XS * Settings.data.general.radiusRatio)
  readonly property int radiusS: Math.round(uiStyleTokens.radii.S * Settings.data.general.radiusRatio)
  readonly property int radiusM: Math.round(uiStyleTokens.radii.M * Settings.data.general.radiusRatio)
  readonly property int radiusL: Math.round(uiStyleTokens.radii.L * Settings.data.general.radiusRatio)

  // Input radii: interactive elements (buttons, toggles, text fields)
  readonly property int iRadiusXXXS: Math.round(uiStyleTokens.inputRadii.XXXS * Settings.data.general.iRadiusRatio)
  readonly property int iRadiusXXS: Math.round(uiStyleTokens.inputRadii.XXS * Settings.data.general.iRadiusRatio)
  readonly property int iRadiusXS: Math.round(uiStyleTokens.inputRadii.XS * Settings.data.general.iRadiusRatio)
  readonly property int iRadiusS: Math.round(uiStyleTokens.inputRadii.S * Settings.data.general.iRadiusRatio)
  readonly property int iRadiusM: Math.round(uiStyleTokens.inputRadii.M * Settings.data.general.iRadiusRatio)
  readonly property int iRadiusL: Math.round(uiStyleTokens.inputRadii.L * Settings.data.general.iRadiusRatio)

  readonly property int screenRadius: Math.round(uiStyleTokens.screenRadius * Settings.data.general.screenRadiusRatio)

  // Border
  readonly property int borderS: Math.max(1, Math.round(uiStyleTokens.borders.S * uiScaleRatio))
  readonly property int borderM: Math.max(1, Math.round(uiStyleTokens.borders.M * uiScaleRatio))
  readonly property int borderL: Math.max(1, Math.round(uiStyleTokens.borders.L * uiScaleRatio))

  // Margins (for margins and spacing)
  readonly property int marginXXXS: Math.round(uiStyleTokens.margins.XXXS * uiScaleRatio)
  readonly property int marginXXS: Math.round(uiStyleTokens.margins.XXS * uiScaleRatio)
  readonly property int marginXS: Math.round(uiStyleTokens.margins.XS * uiScaleRatio)
  readonly property int marginS: Math.round(uiStyleTokens.margins.S * uiScaleRatio)
  readonly property int marginM: Math.round(uiStyleTokens.margins.M * uiScaleRatio)
  readonly property int marginL: Math.round(uiStyleTokens.margins.L * uiScaleRatio)
  readonly property int marginXL: Math.round(uiStyleTokens.margins.XL * uiScaleRatio)

  // Double margins, for proper container sizing only (e.g. height: id.implicitHeight + Style.margin2M)
  readonly property int margin2XXXS: marginXXXS * 2
  readonly property int margin2XXS: marginXXS * 2
  readonly property int margin2XS: marginXS * 2
  readonly property int margin2S: marginS * 2
  readonly property int margin2M: marginM * 2
  readonly property int margin2L: marginL * 2
  readonly property int margin2XL: marginXL * 2

  // Opacity
  readonly property real opacityNone: 0.0
  readonly property real opacityLight: 0.25
  readonly property real opacityMedium: 0.5
  readonly property real opacityHeavy: 0.75
  readonly property real opacityAlmost: 0.95
  readonly property real opacityFull: 1.0

  readonly property real effectivePanelOpacity: PowerProfileService.frostaliaPerformanceMode ? 1.0 : ShellColors.adaptiveOpacity(Settings.data.ui.panelBackgroundOpacity)
  readonly property real effectiveBarOpacity: PowerProfileService.frostaliaPerformanceMode ? 1.0 : Settings.data.bar.backgroundOpacity

  // Shadows
  readonly property real shadowOpacity: 0.85
  readonly property real shadowBlur: 1.0
  readonly property int shadowBlurMax: 22
  readonly property real shadowHorizontalOffset: Settings.data.general.shadowOffsetX
  readonly property real shadowVerticalOffset: Settings.data.general.shadowOffsetY

  // Animation duration (ms)
  readonly property int animationFaster: (Settings.data.general.animationDisabled || PowerProfileService.frostaliaPerformanceMode) ? 0 : Math.round(uiStyleTokens.animations.Faster / Settings.data.general.animationSpeed)
  readonly property int animationFast: (Settings.data.general.animationDisabled || PowerProfileService.frostaliaPerformanceMode) ? 0 : Math.round(uiStyleTokens.animations.Fast / Settings.data.general.animationSpeed)
  readonly property int animationNormal: (Settings.data.general.animationDisabled || PowerProfileService.frostaliaPerformanceMode) ? 0 : Math.round(uiStyleTokens.animations.Normal / Settings.data.general.animationSpeed)
  readonly property int animationSlow: (Settings.data.general.animationDisabled || PowerProfileService.frostaliaPerformanceMode) ? 0 : Math.round(uiStyleTokens.animations.Slow / Settings.data.general.animationSpeed)
  readonly property int animationSlowest: (Settings.data.general.animationDisabled || PowerProfileService.frostaliaPerformanceMode) ? 0 : Math.round(uiStyleTokens.animations.Slowest / Settings.data.general.animationSpeed)

  // Delays
  readonly property int tooltipDelay: 300
  readonly property int tooltipDelayLong: 1200
  readonly property int pillDelay: 500

  // Widgets base size
  readonly property real baseWidgetSize: uiStyleTokens.baseWidgetSize
  readonly property real sliderWidth: uiStyleTokens.sliderWidth

  readonly property real uiScaleRatio: Settings.data.general.scaleRatio

  // Bar Height
  readonly property real barHeight: {
    let h;
    switch (Settings.data.bar.density) {
    case "mini":
      h = (Settings.data.bar.position === "left" || Settings.data.bar.position === "right") ? 23 : 21;
      break;
    case "compact":
      h = (Settings.data.bar.position === "left" || Settings.data.bar.position === "right") ? 27 : 25;
      break;
    case "comfortable":
      h = (Settings.data.bar.position === "left" || Settings.data.bar.position === "right") ? 39 : 37;
      break;
    case "spacious":
      h = (Settings.data.bar.position === "left" || Settings.data.bar.position === "right") ? 49 : 47;
      break;
    default:
    case "default":
      h = (Settings.data.bar.position === "left" || Settings.data.bar.position === "right") ? 33 : 31;
    }
    return toOdd(h);
  }

  // Capsule Height
  // Note: capsule must always be smaller than barHeight to account for border rendering
  // Qt Quick Rectangle borders are drawn centered on edges (half inside, half outside)
  readonly property real capsuleHeight: {
    let h;
    switch (Settings.data.bar.density) {
    case "mini":
      h = Math.round(barHeight * 0.90);
      break;
    case "compact":
      h = Math.round(barHeight * 0.85);
      break;
    case "comfortable":
      h = Math.round(barHeight * 0.75);
      break;
    case "spacious":
      h = Math.round(barHeight * 0.65);
      break;
    default:
      h = Math.round(barHeight * 0.82);
      break;
    }
    return toOdd(h);
  }

  // The base/default font size for all texts in the bar
  readonly property real _barBaseFontSize: Math.max(1, (Style.barHeight / Style.capsuleHeight) * Style.fontSizeXXS)
  readonly property real barFontSize: (Settings.data.bar.position === "left" || Settings.data.bar.position === "right") ? _barBaseFontSize * 0.9 * Settings.data.bar.fontScale : _barBaseFontSize * Settings.data.bar.fontScale

  readonly property color capsuleColor: Settings.data.bar.showCapsule ? Qt.alpha(Settings.data.bar.capsuleColorKey !== "none" ? ShellColors.resolveColorKey(Settings.data.bar.capsuleColorKey) : ShellColors.mSurfaceVariant, Settings.data.bar.capsuleOpacity) : "transparent"

  readonly property color capsuleBorderColor: Settings.data.bar.showOutline ? ShellColors.mPrimary : "transparent"
  readonly property int capsuleBorderWidth: Settings.data.bar.showOutline ? Style.borderS : 0

  function widgetBackground(section, color) {
    return BubbleLogic.widgetBackground(section, color);
  }

  function widgetBorder(section, color) {
    return BubbleLogic.widgetBackground(section, color);
  }

  // Container outlines (NBox and friends): color key, brightness and opacity from settings
  readonly property color boxBorderColor: {
    if (!Settings.data.ui.boxBorderEnabled)
      return "transparent";
    const base = ShellColors.resolveColorKey(Settings.data.ui.boxBorderColor);
    const c = OutlineStyle.outlineColor({
                                          "r": base.r,
                                          "g": base.g,
                                          "b": base.b,
                                          "a": base.a
                                        }, Settings.data.ui.boxBorderBrightness, Settings.data.ui.boxBorderOpacity);
    return Qt.rgba(c.r, c.g, c.b, c.a);
  }
  readonly property int boxBorderWidth: OutlineStyle.borderWidth(Settings.data.ui.boxBorderWidth, uiScaleRatio)

  // Pixel-perfect utility for centering content without subpixel positioning
  function pixelAlignCenter(containerSize, contentSize) {
    return Math.round((containerSize - contentSize) / 2);
  }

  // Ensures a number is always odd (rounds down to nearest odd)
  function toOdd(n) {
    return Math.floor(n / 2) * 2 + 1;
  }

  // Ensures a number is always even (rounds down to nearest even)
  function toEven(n) {
    return Math.floor(n / 2) * 2;
  }

  // Get bar height for a specific density and orientation
  function getBarHeightForDensity(density, isVertical) {
    let h;
    switch (density) {
    case "mini":
      h = isVertical ? 23 : 21;
      break;
    case "compact":
      h = isVertical ? 27 : 25;
      break;
    case "comfortable":
      h = isVertical ? 39 : 37;
      break;
    case "spacious":
      h = isVertical ? 49 : 47;
      break;
    default:
    case "default":
      h = isVertical ? 33 : 31;
    }
    return toOdd(h);
  }

  // Get capsule height for a specific density and bar height
  function getCapsuleHeightForDensity(density, barHeight) {
    let h;
    switch (density) {
    case "mini":
      h = Math.round(barHeight * 0.90);
      break;
    case "compact":
      h = Math.round(barHeight * 0.85);
      break;
    case "comfortable":
      h = Math.round(barHeight * 0.75);
      break;
    case "spacious":
      h = Math.round(barHeight * 0.65);
      break;
    default:
      h = Math.round(barHeight * 0.82);
      break;
    }
    return toOdd(h);
  }

  // Get bar font size for a specific bar height, capsule height, and orientation
  function getBarFontSizeForDensity(barHeight, capsuleHeight, isVertical) {
    const baseFontSize = Math.max(1, (barHeight / capsuleHeight) * Style.fontSizeXXS);
    return isVertical ? baseFontSize * 0.9 * Settings.data.bar.fontScale : baseFontSize * Settings.data.bar.fontScale;
  }

  // Convenience functions for per-screen bar sizing
  function getBarHeightForScreen(screenName, section) {
    var bubble = Settings.getBubble(screenName, section);
    if (bubble)
      return bubble.height;
    var density = Settings.getBarDensityForScreen(screenName);
    var position = Settings.getBarPositionForScreen(screenName, section);
    var isVertical = position === "left" || position === "right";
    return getBarHeightForDensity(density, isVertical);
  }

  // Notch bar: empty gap left at each end of the bar's edge
  function getBarNotchInsetForScreen(screen) {
    if (Settings.data.bar.barType !== "notch" || !screen)
      return 0;
    var position = Settings.getBarPositionForScreen(screen.name);
    var edgeLength = NotchGeometry.isVertical(position) ? screen.height : screen.width;
    return NotchGeometry.inset(edgeLength, Settings.data.bar.notchGap ?? 180);
  }

  function getCapsuleHeightForScreen(screenName, section) {
    var barHeight = getBarHeightForScreen(screenName, section);
    var density = Settings.getBarDensityForScreen(screenName);
    return getCapsuleHeightForDensity(density, barHeight);
  }

  function getBarFontSizeForScreen(screenName, section) {
    var barHeight = getBarHeightForScreen(screenName, section);
    var capsuleHeight = getCapsuleHeightForScreen(screenName, section);
    var position = Settings.getBarPositionForScreen(screenName, section);
    var isVertical = position === "left" || position === "right";
    return getBarFontSizeForDensity(barHeight, capsuleHeight, isVertical);
  }
}
