pragma Singleton

import QtQuick
import Quickshell
import "../Helpers/KeycapStyle.js" as KeycapStyle

// Colors, metrics and glyphs for Keycap style faces (Modules/Bar/Widgets/Keycap).
// Faces only talk to this object, so tests can hand them a plain stand-in.
Singleton {
  id: root

  readonly property var tokens: Style.keycapTokens || ({
                                                         "cream": "#fff3dc",
                                                         "overshoot": 2.2,
                                                         "popOvershoot": 1.6,
                                                         "tilt": 4,
                                                         "barDepth": 2
                                                       })

  // Palette
  readonly property color cream: tokens.cream
  readonly property color ink: toColor(KeycapStyle.ink(ShellColors.mSurface))
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
  readonly property real depth: Style.keycapDepth
  readonly property real pressedDepth: Style.keycapPressedDepth
  readonly property real hoverLift: Style.keycapHoverLift
  readonly property real outline: Style.keycapOutline
  readonly property real ring: Style.keycapRing
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
    return toColor(KeycapStyle.readableOn(color, ink, cream));
  }

  function mix(a, b, t) {
    return toColor(KeycapStyle.mix(a, b, t));
  }

  // Face depth for a bar section, limited by the room around the capsule.
  function barDepth(screenName, section) {
    const preferred = Math.round(tokens.barDepth * Style.uiScaleRatio);
    return KeycapStyle.barDepth(Style.getBarHeightForScreen(screenName, section), Style.getCapsuleHeightForScreen(screenName, section), preferred);
  }
}
