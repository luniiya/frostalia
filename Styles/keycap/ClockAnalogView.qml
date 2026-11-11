import QtQuick
import "KeycapStyle.js" as KeycapStyle
import qs.Commons

// Keycap analog clock: the dial is a round raised key, the hands are chunky
// outlined bars with hard shadows straight down, and each one snaps to its new
// angle with an overshoot, so the second hand ticks. NClock binds the properties.
Item {
  id: root

  property var now: new Date()
  property color backgroundColor
  property color clockColor
  property color secondHandColor: kit.error
  property real scaleRatio: 1

  readonly property var kit: Style.kit
  readonly property var angles: KeycapStyle.clockAngles(now)
  readonly property real depth: Math.max(1, Math.round(kit.depth * scaleRatio))
  readonly property real outline: Math.max(1, Math.round(kit.outline * scaleRatio))
  readonly property real handDepth: Math.max(1, Math.round(depth * 0.75))
  readonly property real size: Math.max(0, Math.min(width, height - depth))
  readonly property real r: size / 2

  anchors.fill: parent

  // A hand pivots on the dial's center; `drop` moves its shadow straight down.
  component Hand: Item {
    id: hand
    property real length
    property real thickness
    property real tail: thickness / 2
    property real angle
    property real drop: 0
    property color fillColor
    property real outlineWidth: root.outline
    x: root.r
    y: root.r + drop
    rotation: angle

    Behavior on rotation {
      enabled: root.kit.animated
      RotationAnimation {
        direction: RotationAnimation.Clockwise
        duration: root.kit.fast
        easing.type: Easing.OutBack
        easing.overshoot: root.kit.overshoot
      }
    }

    Rectangle {
      x: -hand.thickness / 2
      y: -hand.length
      width: hand.thickness
      height: hand.length + hand.tail
      radius: hand.thickness / 2
      color: hand.fillColor
      border.color: root.kit.ink
      border.width: hand.drop > 0 ? 0 : hand.outlineWidth
      antialiasing: true
    }
  }

  Key {
    id: dial
    x: Math.round((root.width - root.size) / 2)
    y: Math.round((root.height - root.size - root.depth) / 2)
    width: root.size
    height: root.size
    radius: root.size / 2
    fillColor: root.kit.fill
    inkColor: root.kit.ink
    ringColor: root.kit.ringFor(root.kit.fill)
    outlineWidth: root.outline
    ringWidth: root.kit.ring
    depth: root.depth
    hoverLift: 0

    // Hour marks: a round sticker at each quarter, short ink bars between
    Repeater {
      model: 12

      Item {
        required property int index
        readonly property bool quarter: index % 3 === 0
        x: root.r
        y: root.r
        rotation: index * 30

        Rectangle {
          width: parent.quarter ? root.r * 0.17 : root.r * 0.07
          height: parent.quarter ? width : root.r * 0.15
          radius: width / 2
          x: -width / 2
          y: -root.r * 0.84
          color: parent.quarter ? root.kit.primary : root.kit.ink
          border.color: root.kit.ink
          border.width: parent.quarter ? Math.max(1, root.outline - 1) : 0
          antialiasing: true
        }
      }
    }

    // Shadows first, so every hand sits above every shadow
    Hand {
      length: root.r * 0.5
      thickness: root.r * 0.17
      angle: root.angles.hour
      drop: root.handDepth
      fillColor: root.kit.ink
    }
    Hand {
      length: root.r * 0.74
      thickness: root.r * 0.12
      angle: root.angles.minute
      drop: root.handDepth
      fillColor: root.kit.ink
    }
    Hand {
      length: root.r * 0.8
      thickness: Math.max(2, root.r * 0.05)
      tail: root.r * 0.2
      angle: root.angles.second
      drop: root.handDepth
      fillColor: root.kit.ink
    }

    Hand {
      length: root.r * 0.5
      thickness: root.r * 0.17
      angle: root.angles.hour
      fillColor: root.kit.primary
    }
    Hand {
      length: root.r * 0.74
      thickness: root.r * 0.12
      angle: root.angles.minute
      fillColor: root.kit.cream
    }
    Hand {
      length: root.r * 0.8
      thickness: Math.max(2, root.r * 0.05)
      tail: root.r * 0.2
      angle: root.angles.second
      fillColor: root.secondHandColor
      outlineWidth: 0
    }

    // Center cap
    Rectangle {
      width: root.r * 0.18
      height: width
      radius: width / 2
      x: root.r - width / 2
      y: root.r - height / 2
      color: root.secondHandColor
      border.color: root.kit.ink
      border.width: root.outline
      antialiasing: true
    }
  }
}
