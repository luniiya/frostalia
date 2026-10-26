import QtQuick
import "../Helpers/KeycapStyle.js" as KeycapStyle

// Keycap surface: ink outline, thin cream ring, fill and a hard shadow straight
// down. The face fills the item; the shadow sits `depth` px below it. Pressing
// (or `latched`) sinks the face into the shadow, release springs back.
// Children go on the face and sink with it. Free of shell singletons so tests
// can load it; callers pass colors and metrics.
Item {
  id: root

  default property alias content: contentLayer.data

  property color fillColor: "#e8e2d4"
  property color inkColor: "#1d1b20"
  property color ringColor: "#fff3dc"
  property color shadowColor: inkColor
  property real radius: 8
  property real topLeftRadius: radius
  property real topRightRadius: radius
  property real bottomLeftRadius: radius
  property real bottomRightRadius: radius
  property real outlineWidth: 2
  property real ringWidth: 1
  property real depth: 3
  property real pressedDepth: 1
  property real hoverLift: 1
  property bool pressed: false
  property bool hovered: false
  property bool latched: false
  property int duration: 160
  property real overshoot: 2.2

  // Face offset from rest: negative while lifted, positive while sunk.
  readonly property real sink: KeycapStyle.sink(depth, pressedDepth, hoverLift, pressed || latched, hovered)
  readonly property real faceY: face.y
  readonly property Item face: face

  Rectangle {
    id: shadow
    y: root.depth
    width: root.width
    height: root.height
    topLeftRadius: root.topLeftRadius
    topRightRadius: root.topRightRadius
    bottomLeftRadius: root.bottomLeftRadius
    bottomRightRadius: root.bottomRightRadius
    color: root.shadowColor
    visible: root.depth > 0
  }

  Rectangle {
    id: face
    y: root.sink
    width: root.width
    height: root.height
    topLeftRadius: root.topLeftRadius
    topRightRadius: root.topRightRadius
    bottomLeftRadius: root.bottomLeftRadius
    bottomRightRadius: root.bottomRightRadius
    color: root.fillColor
    border.color: root.inkColor
    border.width: root.outlineWidth

    Behavior on y {
      NumberAnimation {
        duration: root.pressed || root.latched ? Math.round(root.duration / 2) : root.duration
        easing.type: root.pressed || root.latched ? Easing.OutQuad : Easing.OutBack
        easing.overshoot: root.overshoot
      }
    }

    Behavior on color {
      ColorAnimation {
        duration: root.duration
      }
    }

    Rectangle {
      anchors.fill: parent
      anchors.margins: root.outlineWidth
      topLeftRadius: Math.max(0, root.topLeftRadius - root.outlineWidth)
      topRightRadius: Math.max(0, root.topRightRadius - root.outlineWidth)
      bottomLeftRadius: Math.max(0, root.bottomLeftRadius - root.outlineWidth)
      bottomRightRadius: Math.max(0, root.bottomRightRadius - root.outlineWidth)
      color: "transparent"
      border.color: root.ringColor
      border.width: root.ringWidth
      visible: root.ringWidth > 0 && width > 2 * root.ringWidth
    }

    Item {
      id: contentLayer
      anchors.fill: parent
    }
  }
}
