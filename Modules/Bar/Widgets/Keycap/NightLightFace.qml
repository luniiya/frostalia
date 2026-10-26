import QtQuick

// Night light: a lamp key. When the filter is on, warm rings glow around
// the icon like a lit bulb.
KeycapFace {
  id: face

  readonly property bool lit: !!faceData.enabled
  readonly property color hostFill: host && host.colorBg !== undefined && host.colorBg.a > 0.05 ? Qt.rgba(host.colorBg.r, host.colorBg.g, host.colorBg.b, 1) : kit.fill

  ownsIcon: true
  sink: key.y + key.faceY
  onLitChanged: bump()

  FaceKey {
    id: key
    face: face
    fillColor: face.lit ? face.kit.mix(face.kit.fill, face.kit.tertiary, 0.2) : face.hostFill

    Repeater {
      model: 3
      Rectangle {
        required property int index
        anchors.centerIn: parent
        width: key.width * (0.82 - index * 0.18)
        height: width
        radius: width / 2
        color: face.kit.tertiary
        opacity: face.lit ? 0.18 + index * 0.14 : 0

        Behavior on opacity {
          NumberAnimation {
            duration: face.kit.normal
          }
        }
      }
    }

    FaceGlyph {
      kit: face.kit
      anchors.centerIn: parent
      icon: face.host ? face.host.icon : ""
      size: face.host && face.host.buttonSize ? face.host.buttonSize * 0.46 : 9
      color: face.lit ? face.kit.readableOn(face.kit.tertiary) : (face.host && face.host.colorFg !== undefined ? face.host.colorFg : face.kit.fillText)
    }
  }
}
