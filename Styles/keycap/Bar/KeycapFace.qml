import QtQuick

// Base of every Keycap bar face. Faces only draw; the widget keeps its mouse
// areas, tooltips and menus. NStyleFace sets `kit` (Commons/KeycapKit.qml) and
// `host` (the widget or pill) at creation and keeps the state properties bound.
// No shell singletons here, so tests can load faces with a stand-in kit.
Item {
  id: face

  property var kit
  property var host
  property bool hovered: false
  property bool pressed: false
  property var faceData: ({})
  property real depth: 2

  // Read back by the host:
  // offset for content the host draws itself (so it sinks with the face)
  property real sink: 0
  // the face draws the host's icon / all of its content
  property bool ownsIcon: false
  property bool ownsContent: false
  // color for content the host draws on top of the face (transparent: host colors)
  property color contentColor: "transparent"

  // Raise the face by half its shadow so face and shadow stay centered in the bar.
  readonly property real centerShift: -Math.round(depth / 2)

  // Faces pop in with an overshoot instead of fading; bump() replays it.
  property real pop: 1

  function bump() {
    if (kit && kit.animated)
      popAnimation.restart();
  }

  SequentialAnimation {
    id: popAnimation
    NumberAnimation {
      target: face
      property: "pop"
      to: 0.72
      duration: face.kit ? Math.round(face.kit.fast / 2) : 80
      easing.type: Easing.OutQuad
    }
    NumberAnimation {
      target: face
      property: "pop"
      to: 1
      duration: face.kit ? face.kit.normal : 280
      easing.type: Easing.OutBack
      easing.overshoot: face.kit ? face.kit.popOvershoot : 1.6
    }
  }

  Component.onCompleted: {
    if (kit && kit.animated) {
      pop = 0.6;
      popAnimation.restart();
    }
  }
}
