import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import "../Helpers/BatteryLiquid.js" as BatteryLiquid
import qs.Commons

// Battery level as liquid in a container: two waves sliding sideways, rising and falling with the charge.
// Size it from the parent; the empty part shows backgroundColor.
Item {
  id: root

  required property real percentage
  required property bool ready
  required property bool charging

  property color backgroundColor: ShellColors.mSurface
  property color liquidColor: ShellColors.mPrimary
  property real radius: Math.min(width, height) / 2

  readonly property real fraction: BatteryLiquid.fillFraction(percentage, ready)
  readonly property real amplitude: BatteryLiquid.waveAmplitude(width, height)
  readonly property real wavelength: Math.max(1, width)
  readonly property real itemHeight: BatteryLiquid.waveItemHeight(height, amplitude)
  readonly property real liquidTop: BatteryLiquid.waveItemY(fraction, height, amplitude) + amplitude
  readonly property real liquidHeight: Math.max(0, height - liquidTop)
  readonly property bool bubbling: charging && animating
  readonly property bool animating: visible && !Settings.data.general.animationDisabled && fraction > 0 && fraction < 1

  function polygon(phase) {
    return BatteryLiquid.wavePolygon(wavelength, 2, amplitude, itemHeight, phase).map(p => Qt.point(p.x, p.y));
  }

  Rectangle {
    anchors.fill: parent
    radius: root.radius
    color: root.backgroundColor

    Behavior on color {
      enabled: !ShellColors.isTransitioning
      ColorAnimation {
        duration: Style.animationFast
        easing.type: Easing.InOutQuad
      }
    }
  }

  Item {
    id: liquidLayer
    anchors.fill: parent
    layer.enabled: true
    layer.effect: MultiEffect {
      maskEnabled: true
      maskThresholdMin: 0.5
      maskSpreadAtMin: 1.0
      maskSource: liquidMask
    }

    // Level shared by both waves
    property real levelY: BatteryLiquid.waveItemY(root.fraction, root.height, root.amplitude)

    Behavior on levelY {
      enabled: !Settings.data.general.animationDisabled
      NumberAnimation {
        duration: Style.animationSlow
        easing.type: Easing.OutCubic
      }
    }

    // Back wave: paler, drifting the other way
    Shape {
      id: backWave
      y: liquidLayer.levelY
      width: root.wavelength * 2
      height: root.itemHeight
      preferredRendererType: Shape.CurveRenderer
      opacity: 0.45

      ShapePath {
        fillColor: root.liquidColor
        strokeColor: "transparent"
        PathPolyline {
          path: root.polygon(Math.PI / 2)
        }
      }

      NumberAnimation on x {
        running: root.animating
        from: -root.wavelength
        to: 0
        duration: root.charging ? 3800 : 7500
        loops: Animation.Infinite
      }
    }

    Shape {
      id: frontWave
      y: liquidLayer.levelY
      width: root.wavelength * 2
      height: root.itemHeight
      preferredRendererType: Shape.CurveRenderer

      ShapePath {
        fillColor: root.liquidColor
        strokeColor: "transparent"
        PathPolyline {
          path: root.polygon(0)
        }
      }

      NumberAnimation on x {
        running: root.animating
        from: 0
        to: -root.wavelength
        duration: root.charging ? 2500 : 5000
        loops: Animation.Infinite
      }
    }

    // Charging: a few faint bubbles every so often, clipped to the liquid below the surface line
    Item {
      id: bubbleClip
      y: root.liquidTop
      width: parent.width
      height: root.liquidHeight
      clip: true

      Repeater {
        model: 4

        Rectangle {
          id: bubble
          property var spec: BatteryLiquid.bubbleSpec(Math.random, root.width, root.liquidHeight)
          property real progress: 0
          readonly property var pos: BatteryLiquid.bubblePosition(spec, progress, root.liquidHeight)

          width: spec.size
          height: spec.size
          radius: spec.size / 2
          x: pos.x - width / 2
          y: pos.y - height / 2
          color: "white"
          opacity: root.bubbling ? BatteryLiquid.bubbleOpacity(progress, 0.4) : 0

          SequentialAnimation {
            running: root.bubbling
            loops: Animation.Infinite

            // Re-roll the bubble, then wait before it rises; a staggered first start for each one
            ScriptAction {
              script: {
                bubble.progress = 0;
                bubble.spec = BatteryLiquid.bubbleSpec(Math.random, root.width, root.liquidHeight);
              }
            }
            PauseAnimation {
              duration: bubble.spec.rest * (0.2 + index * 0.3)
            }
            NumberAnimation {
              target: bubble
              property: "progress"
              from: 0
              to: 1
              duration: bubble.spec.duration
              easing.type: Easing.InSine
            }
          }
        }
      }
    }
  }

  Item {
    id: liquidMask
    anchors.fill: parent
    visible: false
    layer.enabled: true

    Rectangle {
      anchors.fill: parent
      radius: root.radius
    }
  }
}
