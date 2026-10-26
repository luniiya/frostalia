import QtQuick

// Keep awake: a latching key. While the inhibitor is on it stays pressed
// down, turns tertiary and shows two latch bars under the cup.
KeycapFace {
  id: face

  readonly property bool awake: !!faceData.on
  readonly property rect slot: host && host.iconRect ? host.iconRect : Qt.rect(0, 0, width, height)

  sink: key.y + key.faceY
  contentColor: awake ? kit.tertiaryText : "transparent"
  onAwakeChanged: bump()

  FaceKey {
    id: key
    face: face
    latched: face.awake
    fillColor: face.awake ? face.kit.tertiary : face.kit.fill

    Row {
      visible: face.awake
      x: face.slot.x + (face.slot.width - width) / 2
      y: face.slot.y + face.slot.height - height - face.kit.outline - 1
      spacing: 2
      Repeater {
        model: 2
        Rectangle {
          width: Math.max(3, Math.round(face.slot.width / 6))
          height: Math.max(1, Math.round(face.kit.outline / 2 + 0.5))
          radius: height / 2
          color: face.kit.tertiaryText
        }
      }
    }
  }
}
