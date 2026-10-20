import QtQuick
import QtQuick.Shapes

// A leaf blown across the sky on windy days.
// Adapted from Clavis Shell (GPL-3.0) and Animated Weather Cards (MIT).
Item {
  id: root

  property int leafId: -1
  property color leafColor: "#76993E"
  property real leafScale: 1.0
  property real x0: -100
  property real y0: 0
  property real x1: 0
  property real y1: 0
  property real x2: 0
  property real y2: 0
  property real startRotation: 0
  property real endRotation: 0
  property int duration: 2000
  property real progress: 0
  property bool animationRunning: true

  signal finished(int leafId)

  // Quadratic Bezier flight path
  readonly property real positionX: (1 - progress) * (1 - progress) * x0 + 2 * (1 - progress) * progress * x1 + progress * progress * x2
  readonly property real positionY: (1 - progress) * (1 - progress) * y0 + 2 * (1 - progress) * progress * y1 + progress * progress * y2

  width: 46
  height: 28
  x: positionX - width * 0.5
  y: positionY - height * 0.5
  scale: leafScale
  rotation: startRotation + (endRotation - startRotation) * progress
  opacity: 0.88
  transformOrigin: Item.Center

  Shape {
    anchors.fill: parent
    antialiasing: true
    preferredRendererType: Shape.CurveRenderer
    transform: Translate {
      x: -41.9
      y: -33.8
    }

    ShapePath {
      strokeWidth: 0
      strokeColor: "transparent"
      fillColor: root.leafColor
      PathSvg {
        path: "M41.9,56.3l0.1-2.5c0,0,4.6-1.2,5.6-2.2c1-1,3.6-13,12-15.6c9.7-3.1,19.9-2,26.1-2.1c2.7,0-10,23.9-20.5,25c-7.5,0.8-17.2-5.1-17.2-5.1L41.9,56.3z"
      }
    }
  }

  NumberAnimation on progress {
    from: 0
    to: 1
    duration: root.duration
    easing.type: Easing.Linear
    running: true
    paused: !root.animationRunning
    onFinished: root.finished(root.leafId)
  }
}
