import QtQuick

// Session menu: an emergency stop. A round red cap sits in a flat guard
// collar and sinks deep into it when pressed.
KeycapFace {
  id: face

  ownsIcon: true
  sink: collar.y + cap.y + cap.faceY

  // Guard collar: flat, no shadow of its own
  Rectangle {
    id: collar
    y: face.centerShift + face.depth
    width: face.width
    height: face.height
    radius: Math.min(face.kit.smallRadius, height / 3)
    color: face.kit.fill
    border.color: face.kit.ink
    border.width: face.kit.outline
    scale: face.pop

    Item {
      anchors.fill: parent
      anchors.margins: Math.max(3, Math.round(face.height * 0.14))

      FaceKey {
        id: cap
        face: face
        y: -face.depth
        radius: height / 2
        fillColor: face.kit.error
        depth: face.depth + 1

        FaceGlyph {
          kit: face.kit
          anchors.centerIn: parent
          icon: face.host ? face.host.icon : "power"
          size: face.host && face.host.buttonSize ? face.host.buttonSize * 0.32 : 7
          color: face.kit.errorText
        }
      }
    }
  }
}
