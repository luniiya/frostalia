import QtQuick

// A small key turned on its corner: the lyrics' bouncing marker, the beads of a break
// and the bits of a burst. It springs from big to normal as it lights. After SekaiPop's
// DiamondDot (github.com/Blapples/SekaiPop, GPL-3.0).
Rectangle {
  id: root

  property bool lit: false
  property color litColor: "#7fe0c0"
  property color offColor: "#ffffff"
  property color lineColor: "#2a2140"
  property real size: 12
  property real pop: 1

  width: size
  height: size
  radius: Math.max(2, size * 0.25)
  rotation: 45
  scale: pop
  color: lit ? litColor : offColor
  border.width: 2
  border.color: lineColor
  antialiasing: true

  Behavior on color {
    ColorAnimation {
      duration: 140
    }
  }

  onLitChanged: {
    if (lit)
      bumpAnim.restart();
  }

  NumberAnimation {
    id: bumpAnim
    target: root
    property: "pop"
    from: 1.7
    to: 1
    duration: 360
    easing.type: Easing.OutBack
    easing.overshoot: 2.2
  }
}
