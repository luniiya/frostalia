import QtQuick
import "KeycapStyle.js" as KeycapStyle

// Shade inside a face pushed under the plate (KeycapStyle.crescent): the wall
// above casts it along the top and it follows the rounded ends down the sides.
// Goes on a Key's face; `fillColor` must be the face's color.
Item {
  id: root

  property var kit
  property real depth: 2
  property color color: "black"
  property color fillColor: "white"
  property real topLeftRadius: 0
  property real topRightRadius: 0
  property real bottomLeftRadius: 0
  property real bottomRightRadius: 0

  readonly property real outline: kit ? kit.outline : 0
  readonly property var box: KeycapStyle.innerShade(parent ? parent.width : 0, parent ? parent.height : 0, 0, outline, depth)
  readonly property var shape: KeycapStyle.crescent(parent ? parent.height : 0, outline, depth)

  function inner(r) {
    return KeycapStyle.innerShade(box.width + 2 * outline, box.height + 2 * outline, r, outline, depth).radius;
  }

  x: box.x
  y: box.y
  width: box.width
  height: shape.clip
  clip: true
  // Fade the crescent as one piece; the cover would show the shade through otherwise
  layer.enabled: opacity < 1 && opacity > 0

  Rectangle {
    width: root.box.width
    height: root.box.height
    topLeftRadius: root.inner(root.topLeftRadius)
    topRightRadius: root.inner(root.topRightRadius)
    bottomLeftRadius: root.inner(root.bottomLeftRadius)
    bottomRightRadius: root.inner(root.bottomRightRadius)
    color: root.color
  }

  Rectangle {
    y: root.shape.drop
    width: root.box.width
    height: root.box.height
    topLeftRadius: root.inner(root.topLeftRadius)
    topRightRadius: root.inner(root.topRightRadius)
    bottomLeftRadius: root.inner(root.bottomLeftRadius)
    bottomRightRadius: root.inner(root.bottomRightRadius)
    color: root.fillColor
  }
}
