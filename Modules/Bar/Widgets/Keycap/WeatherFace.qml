import QtQuick

// Weather: an airmail postcard. Red and blue chevron stripes run along the
// top and bottom edges of a cream-tinted card.
KeycapFace {
  id: face

  sink: card.y + card.faceY

  FaceKey {
    id: card
    face: face
    radius: Math.min(face.kit.smallRadius, height / 3)
    fillColor: face.kit.mix(face.kit.fill, face.kit.cream, 0.12)

    Repeater {
      model: 2
      Item {
        required property int index
        x: face.kit.outline + 1
        y: index === 0 ? face.kit.outline + 1 : card.height - height - face.kit.outline - 1
        width: card.width - 2 * (face.kit.outline + 1)
        height: Math.max(2, Math.round(card.height / 10))
        clip: true

        Row {
          spacing: 2
          Repeater {
            model: Math.ceil(card.width / 5) + 1
            Rectangle {
              required property int index
              width: 3
              height: card.height / 4
              y: -height / 3
              rotation: 35
              color: index % 2 === 0 ? face.kit.error : face.kit.primary
            }
          }
        }
      }
    }
  }
}
