import QtQuick

// Control center: a d-pad key. Four studs at north, east, south and west
// light up when you hover, like a pad ready for input.
KeycapFace {
  id: face

  ownsIcon: true
  sink: key.y + key.faceY

  FaceKey {
    id: key
    face: face
    radius: Math.min(face.kit.smallRadius, height / 3)
    fillColor: face.host && face.host.colorBg !== undefined && face.host.colorBg.a > 0.05 ? Qt.rgba(face.host.colorBg.r, face.host.colorBg.g, face.host.colorBg.b, 1) : face.kit.fill

    Repeater {
      model: 4
      Rectangle {
        required property int index
        readonly property real edge: face.kit.outline + 2
        width: Math.max(2, Math.round(key.width / 10))
        height: width
        radius: width / 2
        x: index === 1 ? key.width - width - edge : (index === 3 ? edge : (key.width - width) / 2)
        y: index === 0 ? edge : (index === 2 ? key.height - height - edge : (key.height - height) / 2)
        color: face.hovered ? face.kit.primary : face.kit.mix(face.kit.fill, face.kit.ink, 0.4)

        Behavior on color {
          ColorAnimation {
            duration: face.kit.fast
          }
        }
      }
    }

    FaceGlyph {
      kit: face.kit
      anchors.centerIn: parent
      icon: face.host ? face.host.icon : ""
      size: face.host && face.host.buttonSize ? face.host.buttonSize * 0.4 : 8
      color: face.host && face.host.colorFg !== undefined ? face.host.colorFg : face.kit.fillText
    }
  }
}
