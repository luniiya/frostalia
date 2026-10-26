import QtQuick
import "../KeycapStyle.js" as KeycapStyle

// Network: a round badge sticker stuck on at a slight angle over a flat tab.
// The badge turns secondary while connected.
KeycapFace {
  id: face

  readonly property bool connected: !!faceData.connected
  readonly property rect slot: host && host.iconRect ? host.iconRect : Qt.rect(0, 0, width, height)

  ownsIcon: true
  sink: tab.y + tab.faceY
  onConnectedChanged: bump()

  FaceKey {
    id: tab
    face: face
    depth: Math.max(1, face.depth - 1)
    visible: face.width > face.slot.width + 1 || face.height > face.slot.height + 1
  }

  Item {
    x: face.slot.x
    y: face.slot.y
    width: face.slot.width
    height: face.slot.height

    FaceSticker {
      id: badge
      face: face
      radius: height / 2
      tilt: KeycapStyle.tilt("Network", face.kit.tiltMax)
      bodyColor: face.connected ? face.kit.secondary : face.kit.fill

      FaceGlyph {
        kit: face.kit
        anchors.centerIn: parent
        icon: face.host ? face.host.icon : ""
        size: face.host && face.host.iconSize ? face.host.iconSize * 0.9 : 8
        color: face.connected ? face.kit.secondaryText : face.kit.fillText
      }
    }
  }
}
