import QtQuick
import QtQuick.Shapes

// A keycap with a custom outline from a KeycapStyle path generator:
// `pathFor(width, height)` returns an SVG path. Shadow, ink outline, inset
// cream ring, fill, and the same press sink as a regular key.
Item {
  id: key

  required property var face
  required property var pathFor
  default property alias content: contentLayer.data

  property color fillColor: face.kit.fill
  property color inkColor: face.kit.ink
  property color ringColor: face.kit.ringFor(fillColor)
  property bool latched: false

  readonly property real sink: (face.pressed || latched) ? Math.max(0, face.depth - face.kit.pressedDepth) : (face.hovered ? -face.kit.hoverLift : 0)
  readonly property real outline: face.kit.outline
  readonly property real inset: outline + face.kit.ring / 2
  // Animated face offset, for content drawn outside the key
  readonly property real faceY: faceLayer.y

  width: parent ? parent.width : 0
  height: parent ? parent.height : 0
  y: face.centerShift
  scale: face.pop

  Shape {
    y: key.face.depth
    width: key.width
    height: key.height
    visible: key.face.depth > 0 && key.width > 0 && key.height > 0
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      strokeWidth: key.outline
      strokeColor: key.inkColor
      fillColor: key.inkColor
      PathSvg {
        path: key.pathFor(key.width, key.height)
      }
    }
  }

  Item {
    id: faceLayer
    y: key.sink
    width: key.width
    height: key.height

    Behavior on y {
      NumberAnimation {
        duration: key.face.pressed ? Math.round(key.face.kit.fast / 2) : key.face.kit.fast
        easing.type: key.face.pressed ? Easing.OutQuad : Easing.OutBack
        easing.overshoot: key.face.kit.overshoot
      }
    }

    Shape {
      anchors.fill: parent
      visible: key.width > 0 && key.height > 0
      preferredRendererType: Shape.CurveRenderer
      ShapePath {
        strokeWidth: key.outline
        strokeColor: key.inkColor
        fillColor: key.fillColor
        PathSvg {
          path: key.pathFor(key.width, key.height)
        }
      }
    }

    Shape {
      x: key.inset
      y: key.inset
      width: Math.max(0, key.width - 2 * key.inset)
      height: Math.max(0, key.height - 2 * key.inset)
      visible: width > 4 && height > 4
      preferredRendererType: Shape.CurveRenderer
      ShapePath {
        strokeWidth: key.face.kit.ring
        strokeColor: key.ringColor
        fillColor: "transparent"
        PathSvg {
          path: key.pathFor(Math.max(0, key.width - 2 * key.inset), Math.max(0, key.height - 2 * key.inset))
        }
      }
    }

    Item {
      id: contentLayer
      anchors.fill: parent
    }
  }
}
