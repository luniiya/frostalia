import QtQuick
import "../../Helpers/OsdGeometry.js" as OsdGeometry

// Kept independent of shell services so the endpoint geometry can be tested headless.
Item {
  id: root

  property bool vertical: false
  property real value: 0
  property real maximum: 1
  property color activeColor: "white"
  property color inactiveColor: "gray"
  property color markerColor: "black"
  property int animationDuration: 200
  readonly property real fraction: OsdGeometry.progress(value, maximum)
  property real displayedFraction: fraction
  readonly property var geometry: OsdGeometry.track(vertical ? height : width, vertical ? width : height, displayedFraction, 1)

  Behavior on displayedFraction {
    NumberAnimation {
      duration: root.animationDuration
      easing.type: Easing.OutCubic
    }
  }

  Rectangle {
    anchors.fill: parent
    radius: Math.min(width, height) / 2
    color: root.inactiveColor
  }

  Item {
    id: reveal
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    width: root.vertical ? root.width : root.geometry.filled
    height: root.vertical ? root.geometry.filled : root.height
    clip: true

    Rectangle {
      anchors.left: parent.left
      anchors.bottom: parent.bottom
      width: root.vertical ? root.width : root.geometry.capsule
      height: root.vertical ? root.geometry.capsule : root.height
      radius: Math.min(width, height) / 2
      color: root.activeColor
    }
  }

  Rectangle {
    visible: root.displayedFraction > 0.04 && root.displayedFraction < 0.96
    x: root.vertical ? root.width * 0.3 : root.geometry.marker
    y: root.vertical ? root.height - root.geometry.marker - height : root.height * 0.3
    width: root.vertical ? root.width * 0.4 : 2
    height: root.vertical ? 2 : root.height * 0.4
    radius: 1
    color: root.markerColor
  }
}
