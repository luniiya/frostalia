import QtQuick

// A one-shot puff of diamonds flying out from (0, 0) and fading. Place it and call
// `fire()`; nothing runs between bursts. After SekaiPop's Burst
// (github.com/Blapples/SekaiPop, GPL-3.0).
Item {
  id: root

  property int count: 6
  property real radius: 40
  property real size: 9
  property var colors: ["#ffffff"]
  property color lineColor: "#2a2140"
  // 0 not started, 1 finished; the diamonds are only drawn in between
  property real t: 0

  function fire() {
    anim.restart();
  }

  NumberAnimation {
    id: anim
    target: root
    property: "t"
    from: 0
    to: 1
    duration: 600
    easing.type: Easing.OutCubic
  }

  Repeater {
    model: root.t > 0 && root.t < 1 ? root.count : 0

    DiamondDot {
      required property int index
      readonly property real angle: index * 2 * Math.PI / root.count - Math.PI / 2 + 0.35
      readonly property real reach: root.radius * (0.65 + 0.35 * ((index * 7) % 5) / 4)

      lit: true
      size: root.size
      litColor: root.colors[index % root.colors.length]
      lineColor: root.lineColor
      x: Math.cos(angle) * reach * root.t - width / 2
      y: Math.sin(angle) * reach * root.t - height / 2
      opacity: 1 - root.t * root.t
    }
  }
}
