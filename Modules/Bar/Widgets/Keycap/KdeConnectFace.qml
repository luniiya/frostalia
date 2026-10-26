import QtQuick

// KDE Connect: a little phone. The icon sits on a narrow handset key with a
// speaker slot and a home bar, beside a flat tab for the battery text.
KeycapFace {
  id: face

  readonly property rect slot: host && host.iconRect ? host.iconRect : Qt.rect(0, 0, width, height)

  sink: phone.y + phone.faceY

  FaceKey {
    face: face
    depth: Math.max(1, face.depth - 1)
    visible: face.width > face.slot.width + 1 || face.height > face.slot.height + 1
  }

  Item {
    x: face.slot.x + Math.round(face.slot.width * 0.14)
    y: face.slot.y
    width: Math.round(face.slot.width * 0.72)
    height: face.slot.height

    FaceKey {
      id: phone
      face: face
      radius: Math.round(width * 0.28)
      fillColor: face.kit.mix(face.kit.fill, face.kit.cream, 0.1)

      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: face.kit.outline + 1
        width: Math.round(parent.width * 0.32)
        height: Math.max(1, Math.round(face.kit.outline / 2 + 0.5))
        radius: height / 2
        color: face.kit.ink
      }
      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height - height - face.kit.outline - 1
        width: Math.round(parent.width * 0.4)
        height: Math.max(1, Math.round(face.kit.outline / 2 + 0.5))
        radius: height / 2
        color: face.kit.mix(face.kit.fill, face.kit.ink, 0.5)
      }
    }
  }
}
