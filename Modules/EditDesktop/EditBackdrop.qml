import QtQuick
import QtQuick.Effects
import qs.Commons

// The stage around the card: the wallpaper, blurred and dimmed, so the editor feels open
Item {
  id: root

  property string wallpaper: ""

  Rectangle {
    anchors.fill: parent
    color: Qt.darker(ShellColors.mSurface, 3)
  }

  Image {
    id: source
    anchors.fill: parent
    source: root.wallpaper ? "file://" + root.wallpaper : ""
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    visible: false
  }

  MultiEffect {
    anchors.fill: parent
    source: source
    visible: source.status === Image.Ready
    blurEnabled: true
    blur: 1.0
    blurMax: 64
    saturation: -0.15
    brightness: -0.25
  }

  Rectangle {
    anchors.fill: parent
    color: Qt.alpha(ShellColors.mShadow, 0.35)
  }
}
