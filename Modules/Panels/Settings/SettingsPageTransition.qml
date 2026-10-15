import QtQuick

// One progress value keeps the sidebar's width and both pages' fades in sync.
Item {
  id: root
  property bool pageVisible: false
  property int duration: 0
  readonly property bool transitioning: motion.running
  property real progress: pageVisible ? 1 : 0

  Behavior on progress {
    NumberAnimation {
      id: motion
      duration: root.duration
      easing.type: Easing.InOutCubic
    }
  }
}
