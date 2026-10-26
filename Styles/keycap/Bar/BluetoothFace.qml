import QtQuick
import "../KeycapStyle.js" as KeycapStyle

// Bluetooth: a squircle badge sticker in the tertiary color with one cream
// pip per connected device (up to three) along its top edge.
KeycapFace {
  id: face

  readonly property bool powered: faceData.enabled !== undefined ? !!faceData.enabled : true
  readonly property int devices: Math.max(0, Math.min(3, Math.floor(Number(faceData.devices) || 0)))
  readonly property rect slot: host && host.iconRect ? host.iconRect : Qt.rect(0, 0, width, height)

  ownsIcon: true
  sink: tab.y + tab.faceY
  onDevicesChanged: bump()

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
      radius: Math.round(height * 0.32)
      tilt: KeycapStyle.tilt("Bluetooth", face.kit.tiltMax)
      bodyColor: face.powered ? face.kit.tertiary : face.kit.mix(face.kit.fill, face.kit.ink, 0.3)

      FaceGlyph {
        kit: face.kit
        anchors.centerIn: parent
        anchors.verticalCenterOffset: face.devices > 0 ? 1 : 0
        icon: face.host ? face.host.icon : ""
        size: face.host && face.host.iconSize ? face.host.iconSize * 0.9 : 8
        color: face.powered ? face.kit.tertiaryText : face.kit.fillText
      }

      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 1
        spacing: 1
        Repeater {
          model: face.devices
          Rectangle {
            width: Math.max(2, Math.round(badge.height / 9))
            height: width
            radius: width / 2
            color: face.kit.cream
          }
        }
      }
    }
  }
}
