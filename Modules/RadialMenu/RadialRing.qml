import QtQuick
import QtQuick.Shapes
import "../../Helpers/RadialMenu.js" as RadialLogic
import qs.Commons
import qs.Services.UI
import qs.Widgets

// One level of the radial menu. Its origin is the ring center; the look comes from the
// UI style's radial spec (Helpers/UiStyles.js tokens.radialMenu, RadialMenu.visual()).
Item {
  id: root

  required property var items
  required property var spec
  property real s: 1
  property int hovered: -1
  property bool held: false
  property bool nested: false

  readonly property int count: items.length
  readonly property var hoveredItem: hovered >= 0 && hovered < count ? items[hovered] : null

  // Spec colors to real colors, see RadialMenu.colorSource()
  function color(role) {
    const source = RadialLogic.colorSource(role);
    if (source.kind === "literal")
      return source.value;
    if (source.kind === "ink")
      return Style.kit && Style.kit.ink !== undefined ? Style.kit.ink : ShellColors.mOnSurface;
    const value = ShellColors[source.value];
    return value !== undefined ? value : ShellColors.mPrimary;
  }

  Repeater {
    model: root.items
    delegate: RadialItem {
      ring: root
    }
  }

  RadialCenter {
    ring: root
  }
}
