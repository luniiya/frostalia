import QtQuick

// Battery: a straight, extra-thick die-cut sticker frame. The battery itself
// (liquid, graphic or icon) is drawn by the widget inside the sticker body;
// `cut` tells it how far to inset. faceData.round makes a round sticker
// (KDE Connect liquid mode). Charging or low battery pops the sticker.
KeycapFace {
  id: face

  readonly property bool round: !!faceData.round
  readonly property bool alert: !!faceData.alert
  readonly property color bodyFill: host && host.customBackgroundColor !== undefined && host.customBackgroundColor.a > 0 ? host.customBackgroundColor : kit.fill
  readonly property real cut: sticker.cut

  sink: sticker.y + sticker.faceY
  onAlertChanged: bump()

  FaceSticker {
    id: sticker
    face: face
    cut: Math.max(3, face.kit.outline + 2)
    radius: face.round ? Math.min(width, height) / 2 : Math.min(face.kit.radius, height / 2)
    bodyColor: face.bodyFill
  }
}
