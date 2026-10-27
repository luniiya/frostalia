import QtQuick

// Eco mode: a latching key like keep awake. While eco mode is on it stays
// down and turns tertiary; forced by power saver, a small lock bar sits under
// the bolt to show the key can't be released.
KeycapFace {
  id: face

  readonly property bool on: !!faceData.on
  readonly property bool forced: !!faceData.forced
  readonly property rect slot: host && host.iconRect ? host.iconRect : Qt.rect(0, 0, width, height)

  sink: key.y + key.faceY
  contentColor: on ? kit.tertiaryText : "transparent"
  onOnChanged: bump()

  FaceKey {
    id: key
    face: face
    latched: face.on
    fillColor: face.on ? face.kit.tertiary : face.kit.fill

    Rectangle {
      visible: face.forced
      x: face.slot.x + (face.slot.width - width) / 2
      y: face.slot.y + face.slot.height - height - face.kit.outline - 1
      width: Math.max(6, Math.round(face.slot.width / 2.5))
      height: Math.max(1, Math.round(face.kit.outline / 2 + 0.5))
      radius: height / 2
      color: face.kit.tertiaryText
    }
  }
}
