import QtQuick
import QtQuick.Shapes
import "KeycapStyle.js" as KeycapStyle

// Shade inside a face pushed under the plate (KeycapStyle.crescent): the inner
// shape minus a copy moved down, so the wall above casts it along the top and it
// tapers down the rounded ends. Transparent elsewhere, so it can sit over any
// face content. Fills its parent, the face, inside `outline`. Free of singletons.
Item {
  id: root

  property real outline: 2
  property real depth: 2
  property color color: "black"
  property real radius: 0
  property real topLeftRadius: radius
  property real topRightRadius: radius
  property real bottomLeftRadius: radius
  property real bottomRightRadius: radius

  readonly property real faceWidth: parent ? parent.width : 0
  readonly property real faceHeight: parent ? parent.height : 0
  readonly property var box: KeycapStyle.innerShade(faceWidth, faceHeight, 0, outline, depth)
  readonly property var shape: KeycapStyle.crescent(faceHeight, outline, depth)

  function inner(r) {
    return KeycapStyle.innerShade(faceWidth, faceHeight, r, outline, depth).radius;
  }

  x: box.x
  y: box.y
  width: box.width
  height: shape.clip
  clip: true
  visible: shape.drop > 0 && box.width > 0

  Shape {
    width: root.box.width
    height: root.box.height + root.shape.drop
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      fillColor: root.color
      fillRule: ShapePath.OddEvenFill
      strokeWidth: -1

      PathRectangle {
        width: root.box.width
        height: root.box.height
        topLeftRadius: root.inner(root.topLeftRadius)
        topRightRadius: root.inner(root.topRightRadius)
        bottomLeftRadius: root.inner(root.bottomLeftRadius)
        bottomRightRadius: root.inner(root.bottomRightRadius)
      }
      PathRectangle {
        y: root.shape.drop
        width: root.box.width
        height: root.box.height
        topLeftRadius: root.inner(root.topLeftRadius)
        topRightRadius: root.inner(root.topRightRadius)
        bottomLeftRadius: root.inner(root.bottomLeftRadius)
        bottomRightRadius: root.inner(root.bottomRightRadius)
      }
    }
  }
}
