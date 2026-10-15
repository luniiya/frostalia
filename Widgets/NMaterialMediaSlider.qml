import QtQuick
import QtQuick.Controls
import QtQuick.Shapes
import "../Helpers/MaterialMediaProgress.js" as MediaProgress

Slider {
  id: root
  property bool playing: false
  property bool motionEnabled: true
  property real unit: 1
  property color accent: "#b8d58c"
  property color trackColor: "#626955"
  property real phase: 0
  readonly property bool waving: playing && motionEnabled && visible && enabled
  property real amplitude: waving ? 4 * unit : 0
  readonly property var wavePoints: MediaProgress.points(availableWidth, availableHeight, position, amplitude, 28 * unit, phase)
  implicitWidth: 240 * unit
  implicitHeight: 28 * unit
  padding: 0
  from: 0
  to: 1
  focusPolicy: Qt.StrongFocus
  Accessible.role: Accessible.Slider

  Behavior on amplitude {
    NumberAnimation {
      duration: root.motionEnabled ? 160 : 0
    }
  }
  NumberAnimation on phase {
    from: 0
    to: 2 * Math.PI
    duration: 1200
    loops: Animation.Infinite
    running: root.waving
  }

  background: Item {
    x: root.leftPadding
    y: root.topPadding
    width: root.availableWidth
    height: root.availableHeight
    // Draw in logical playback order, then mirror for right-to-left layouts.
    transform: Scale {
      origin.x: root.availableWidth / 2
      xScale: root.mirrored ? -1 : 1
    }
    Shape {
      anchors.fill: parent
      ShapePath {
        strokeColor: root.accent
        strokeWidth: 3 * root.unit
        capStyle: ShapePath.RoundCap
        fillColor: "transparent"
        PathSvg {
          path: MediaProgress.path(root.wavePoints)
        }
      }
    }
    Rectangle {
      x: Math.min(parent.width, root.position * parent.width + 7 * root.unit)
      y: (parent.height - height) / 2
      width: Math.max(0, parent.width - x)
      height: 3 * root.unit
      radius: height / 2
      color: root.trackColor
    }
  }
  handle: Rectangle {
    width: 4 * root.unit
    height: 16 * root.unit
    radius: width / 2
    x: root.leftPadding + root.visualPosition * root.availableWidth - width / 2
    y: (root.height - height) / 2
    color: root.accent
  }
}
