import QtQuick
import "../KeycapStyle.js" as KeycapStyle

// Inner shade along the top wall of a recessed face (KeycapStyle.innerShade).
// Fills its parent's inner rounded shape, inside the outline.
Item {
  id: root

  property var kit
  property real radius: 0
  property real depth: 2
  property color color: "black"

  readonly property var shape: KeycapStyle.innerShade(parent ? parent.width : 0, parent ? parent.height : 0, radius, kit ? kit.outline : 0, depth)

  x: shape.x
  y: shape.y
  width: shape.width
  height: shape.band
  clip: true

  Rectangle {
    width: root.shape.width
    height: root.shape.height
    radius: root.shape.radius
    color: root.color
  }
}
