import QtQuick
import QtQuick.Shapes
import Quickshell.Widgets
import "../../Helpers/RadialMenu.js" as RadialLogic
import qs.Commons
import qs.Services.UI
import qs.Widgets

// One item of the ring, drawn the way the UI style's radial spec says: a rounded tonal
// segment ("segment") or an outlined keycap wedge on a hard shadow ("chunky"). Its
// origin is the ring center.
Item {
  id: root

  required property var ring
  required property int index
  required property var modelData

  readonly property var spec: ring.spec
  readonly property real s: ring.s
  readonly property int count: ring.count
  readonly property bool hovered: ring.hovered === index
  readonly property bool pressed: hovered && ring.held
  readonly property real angle: RadialLogic.itemAngle(index, count)
  readonly property var anchorPoint: RadialLogic.polar(angle, spec.itemRadius * s)
  readonly property var direction: RadialLogic.polar(angle, 1)
  readonly property bool chunky: spec.shape === "chunky"

  readonly property color fillColor: hovered ? ring.color(spec.colors.hover) : Qt.alpha(ring.color(spec.colors.fill), spec.fillOpacity)
  readonly property color contentColor: hovered ? ring.color(spec.colors.onHover) : ring.color(spec.colors.onFill)

  // Open animation: each wedge grows out of the center after a short stagger
  property real appear: 0
  SequentialAnimation on appear {
    running: true
    PauseAnimation {
      duration: Style.animationNormal > 0 ? RadialLogic.staggerDelay(root.index, root.count, root.spec.stagger) : 0
    }
    NumberAnimation {
      to: 1
      duration: root.spec.animate ? Style.animationNormal : 0
      easing.type: root.spec.easing === "OutBack" ? Easing.OutBack : root.spec.easing === "OutCubic" ? Easing.OutCubic : Easing.OutQuint
    }
  }

  opacity: Math.min(1, appear * 1.5)
  scale: spec.openScale + (1 - spec.openScale) * appear
  rotation: spec.openRotation * (1 - appear)

  // Hover offset: segments slide outwards, keycaps rise off their shadow and sink when pressed
  property real lift: hovered ? (pressed && chunky ? -spec.pressDepth : spec.hoverLift) * s : 0
  Behavior on lift {
    NumberAnimation {
      duration: Style.animationFast
      easing.type: Easing.OutBack
    }
  }
  property real grow: hovered && spec.shape === "segment" ? spec.hoverScale : 1
  Behavior on grow {
    NumberAnimation {
      duration: Style.animationFast
      easing.type: Easing.OutCubic
    }
  }

  // Wedge geometry, inset by the corner radius which the stroke adds back rounded
  readonly property real corner: spec.cornerRadius * s
  readonly property real border: spec.borderWidth * s
  // Thin light ring between the outline and the fill (keycap stickers)
  readonly property real keyline: border > 0 ? spec.keylineWidth * s : 0
  readonly property real edge: corner + border + keyline
  readonly property real extent: (spec.outerRadius + spec.hoverLift + spec.shadowY + 8) * s
  readonly property var geometry: RadialLogic.wedgeShape(index, count, spec.innerRadius * s, spec.outerRadius * s, spec.gap * s, edge)

  // Hard shadow under keycap wedges (no blur)
  Shape {
    visible: root.geometry !== null && root.spec.shadowOpacity > 0
    x: -root.extent + root.spec.shadowX * root.s
    y: -root.extent + root.spec.shadowY * root.s
    width: root.extent * 2
    height: root.extent * 2
    opacity: root.spec.shadowOpacity
    preferredRendererType: Shape.CurveRenderer

    RadialWedgePath {
      geometry: root.geometry
      offset: root.extent
      fillColor: root.ring.color(root.spec.colors.shadow)
      strokeColor: root.ring.color(root.spec.colors.shadow)
      strokeWidth: root.edge * 2
    }
  }

  Item {
    id: body
    x: root.chunky ? 0 : root.direction.x * root.lift
    y: root.chunky ? -root.lift : root.direction.y * root.lift
    scale: root.grow

    Shape {
      visible: root.geometry !== null
      x: -root.extent
      y: -root.extent
      width: root.extent * 2
      height: root.extent * 2
      preferredRendererType: Shape.CurveRenderer

      // Outline: the same path, stroked wider in the outline color underneath the fill
      RadialWedgePath {
        geometry: root.geometry
        offset: root.extent
        fillColor: root.border > 0 ? root.ring.color(root.spec.colors.outline) : "transparent"
        strokeColor: root.border > 0 ? root.ring.color(root.spec.colors.outline) : "transparent"
        strokeWidth: root.border > 0 ? root.edge * 2 : 0
      }
      RadialWedgePath {
        geometry: root.geometry
        offset: root.extent
        fillColor: root.keyline > 0 ? root.ring.color(root.spec.colors.keyline) : "transparent"
        strokeColor: root.keyline > 0 ? root.ring.color(root.spec.colors.keyline) : "transparent"
        strokeWidth: root.keyline > 0 ? (root.corner + root.keyline) * 2 : 0
      }
      RadialWedgePath {
        geometry: root.geometry
        offset: root.extent
        fillColor: root.fillColor
        strokeColor: root.fillColor
        strokeWidth: root.corner * 2
      }
    }

    // Folders get a dot on their outer edge
    Rectangle {
      visible: root.modelData.action === "folder"
      readonly property real d: 5 * root.s
      readonly property var p: RadialLogic.polar(root.angle, root.spec.outerRadius * root.s - root.border - 9 * root.s)
      x: p.x - d / 2
      y: p.y - d / 2
      width: d
      height: d
      radius: d / 2
      antialiasing: true
      color: Qt.alpha(root.contentColor, 0.75)
    }

    Item {
      id: content
      x: root.anchorPoint.x
      y: root.anchorPoint.y
      rotation: root.chunky && root.hovered ? -root.spec.tilt : 0
      readonly property real iconSize: root.spec.iconSize * root.s
      readonly property string appIcon: RadialMenuService.appIconSource(root.modelData)

      Behavior on rotation {
        NumberAnimation {
          duration: Style.animationFast
          easing.type: Easing.OutBack
        }
      }

      IconImage {
        visible: content.appIcon !== ""
        x: -width / 2
        y: -height / 2
        implicitSize: content.iconSize * 1.4
        source: content.appIcon
        asynchronous: true
      }

      NIcon {
        visible: content.appIcon === ""
        x: -width / 2
        y: -height / 2
        icon: RadialLogic.iconFor(root.modelData)
        pointSize: content.iconSize * 0.75
        applyUiScale: false
        color: root.contentColor

        Behavior on color {
          ColorAnimation {
            duration: Style.animationFast
          }
        }
      }
    }
  }
}
