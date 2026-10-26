import QtQuick

// Microphone: a capsule key with an on-air lamp. The lamp glows while the
// mic is live; muting dims the key and turns the lamp off.
KeycapFace {
  id: face

  readonly property bool muted: !!faceData.muted
  readonly property rect slot: host && host.iconRect ? host.iconRect : Qt.rect(0, 0, width, height)

  sink: key.y + key.faceY
  onMutedChanged: bump()

  FaceKey {
    id: key
    face: face
    radius: height / 2
    fillColor: face.muted ? face.kit.surface : face.kit.fill

    Rectangle {
      width: Math.max(4, Math.round(face.slot.height / 5))
      height: width
      radius: width / 2
      x: face.slot.x + face.slot.width - width - Math.round(face.slot.width * 0.16)
      y: face.slot.y + Math.round(face.slot.height * 0.14)
      color: face.muted ? face.kit.mix(face.kit.fill, face.kit.ink, 0.4) : face.kit.error
      border.color: face.kit.ink
      border.width: 1

      // Glow
      Rectangle {
        anchors.centerIn: parent
        width: parent.width * 2
        height: width
        radius: width / 2
        color: face.kit.error
        opacity: face.muted ? 0 : 0.25
        z: -1
      }
    }
  }
}
