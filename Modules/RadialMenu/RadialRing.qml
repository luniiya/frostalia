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
      return Qt.rgba(ShellColors.mSurface.r * source.value, ShellColors.mSurface.g * source.value, ShellColors.mSurface.b * source.value, 1);
    const value = ShellColors[source.value];
    return value !== undefined ? value : ShellColors.mPrimary;
  }

  // Orbit track and the arc that sweeps to the hovered bubble
  Shape {
    id: orbit
    visible: root.spec.shape === "orbit"
    readonly property real r: root.spec.itemRadius * root.s
    // The highlight hugs the outside of the (grown) hovered bubble
    readonly property real highlightRadius: (root.spec.itemRadius + root.spec.bubbleRadius * root.spec.hoverScale + 6) * root.s
    readonly property real extent: highlightRadius + 8 * root.s
    x: -extent
    y: -extent
    width: extent * 2
    height: extent * 2
    preferredRendererType: Shape.CurveRenderer

    property real appear: 0
    NumberAnimation on appear {
      to: 1
      duration: Style.animationSlow
      easing.type: Easing.OutCubic
    }

    // Shortest way round when the hover jumps across 0 degrees
    property real arcAngle: 0
    Behavior on arcAngle {
      NumberAnimation {
        duration: Style.animationFast
        easing.type: Easing.OutCubic
      }
    }
    function follow() {
      if (root.hovered >= 0)
        arcAngle = RadialLogic.nearestAngle(arcAngle, RadialLogic.itemAngle(root.hovered, root.count));
    }
    Component.onCompleted: follow()
    Connections {
      target: root
      function onHoveredChanged() {
        orbit.follow();
      }
    }

    ShapePath {
      fillColor: "transparent"
      strokeColor: Qt.alpha(root.color(root.spec.colors.track), 0.3)
      strokeWidth: Math.max(1, root.spec.trackWidth * root.s)
      PathAngleArc {
        centerX: orbit.extent
        centerY: orbit.extent
        radiusX: orbit.r
        radiusY: orbit.r
        startAngle: -90
        sweepAngle: 360 * orbit.appear
      }
    }
    ShapePath {
      fillColor: "transparent"
      strokeColor: root.hovered >= 0 ? root.color(root.spec.colors.track) : "transparent"
      strokeWidth: Math.max(2, root.spec.trackWidth * 2 * root.s)
      capStyle: ShapePath.RoundCap
      PathAngleArc {
        centerX: orbit.extent
        centerY: orbit.extent
        radiusX: orbit.highlightRadius
        radiusY: orbit.highlightRadius
        readonly property real sweep: root.count > 0 ? 360 / root.count * 0.5 : 0
        startAngle: orbit.arcAngle - 90 - sweep / 2
        sweepAngle: sweep
      }
    }
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
