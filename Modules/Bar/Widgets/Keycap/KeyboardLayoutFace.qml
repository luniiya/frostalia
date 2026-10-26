import QtQuick

// Keyboard layout: a real keyboard key. Squarer corners, a sculpted top
// surface sitting on a wider skirt, and the homing bump of the F and J keys.
KeycapFace {
  id: face

  sink: key.y + key.faceY

  FaceKey {
    id: key
    face: face
    radius: Math.min(face.kit.smallRadius, height / 3)
    fillColor: face.kit.mix(face.kit.fill, face.kit.ink, 0.12)

    // Top surface (the dish), lighter and slightly forward
    Rectangle {
      anchors.fill: parent
      anchors.leftMargin: Math.max(3, face.kit.outline + 2)
      anchors.rightMargin: Math.max(3, face.kit.outline + 2)
      anchors.topMargin: face.kit.outline + 1
      anchors.bottomMargin: Math.max(4, face.kit.outline + 3)
      radius: Math.max(1, key.radius - 2)
      color: face.kit.fill
      border.color: face.kit.mix(face.kit.fill, face.kit.ink, 0.3)
      border.width: 1

      // Homing bump
      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 2
        width: Math.max(4, Math.round(parent.width * 0.22))
        height: Math.max(1, Math.round(face.kit.outline / 2 + 0.5))
        radius: height / 2
        color: face.kit.mix(face.kit.fill, face.kit.ink, 0.5)
      }
    }
  }
}
