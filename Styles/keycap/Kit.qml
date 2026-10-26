import QtQuick
import qs.Commons
import "KeycapStyle.js" as KeycapStyle

// Colors, metrics and glyphs shared by the Keycap skins and bar faces (Bar/). The
// definition names this file as its `kit`; Style.kit is the one live instance.
// Faces only talk to the kit they are handed, so tests can give them a plain stand-in.
QtObject {
  id: root

  readonly property var tokens: Style.uiStyleTokens.keycap || ({
                                                         "cream": "#fff3dc",
                                                         "overshoot": 2.2,
                                                         "popOvershoot": 1.6,
                                                         "tilt": 4,
                                                         "depth": 3,
                                                         "pressedDepth": 1,
                                                         "hoverLift": 1,
                                                         "outline": 2,
                                                         "ring": 1
                                                       })

  // Palette
  readonly property color cream: tokens.cream
  // Outlines and hard shadows: dark on light schemes, light on dark ones
  readonly property color ink: toColor(KeycapStyle.ink(ShellColors.mSurface))
  // Always dark: text and the dark half of two-tone keys
  readonly property color shade: toColor(KeycapStyle.shade(ShellColors.mSurface))
  // Keycaps are solid: the capsule color key picks the fill, its opacity is ignored.
  readonly property color fill: Settings.data.bar.capsuleColorKey !== "none" ? ShellColors.resolveColorKey(Settings.data.bar.capsuleColorKey) : ShellColors.mSurfaceVariant
  readonly property color fillText: readableOn(fill)
  readonly property color primary: ShellColors.mPrimary
  readonly property color primaryText: ShellColors.mOnPrimary
  readonly property color secondary: ShellColors.mSecondary
  readonly property color secondaryText: ShellColors.mOnSecondary
  readonly property color tertiary: ShellColors.mTertiary
  readonly property color tertiaryText: ShellColors.mOnTertiary
  readonly property color error: ShellColors.mError
  readonly property color errorText: ShellColors.mOnError
  readonly property color surface: ShellColors.mSurface
  readonly property color surfaceText: ShellColors.mOnSurface
  readonly property color surfaceVariant: ShellColors.mSurfaceVariant
  readonly property color surfaceVariantText: ShellColors.mOnSurfaceVariant
  readonly property color hover: ShellColors.mHover
  readonly property color hoverText: ShellColors.mOnHover

  // Metrics
  // Hard shadow depth, press depth and hover lift, scaled
  readonly property int depth: Math.max(1, Math.round(tokens.depth * Style.uiScaleRatio))
  readonly property int pressedDepth: Math.round(tokens.pressedDepth * Style.uiScaleRatio)
  readonly property int hoverLift: Math.round(tokens.hoverLift * Style.uiScaleRatio)
  readonly property int outline: Math.max(1, Math.round(tokens.outline * Style.uiScaleRatio))
  readonly property int ring: Math.max(1, Math.round(tokens.ring * Style.uiScaleRatio))
  readonly property real radius: Style.radiusM
  readonly property real smallRadius: Style.radiusXS
  readonly property real tiltMax: tokens.tilt
  readonly property real overshoot: tokens.overshoot
  readonly property real popOvershoot: tokens.popOvershoot

  // Motion
  readonly property bool animated: Style.animationNormal > 0
  readonly property int fast: Style.animationFast
  readonly property int normal: Style.animationNormal
  readonly property int slow: Style.animationSlow

  // Type
  readonly property string fontFamily: Style.fontDefault
  readonly property string fontFixed: Style.fontFixed
  readonly property int fontWeightBold: Style.fontWeightBold
  readonly property string iconFamily: Icons.fontFamily

  function toColor(c) {
    return Qt.rgba(c.r, c.g, c.b, c.a === undefined ? 1 : c.a);
  }

  function glyph(name) {
    if (!name)
      return "";
    return Icons.get(name) ?? Icons.get(Icons.defaultIcon);
  }

  function ringFor(color) {
    return toColor(KeycapStyle.ring(color, cream));
  }

  function readableOn(color) {
    return toColor(KeycapStyle.readableOn(color, shade, cream));
  }

  function mix(a, b, t) {
    return toColor(KeycapStyle.mix(a, b, t));
  }
}
