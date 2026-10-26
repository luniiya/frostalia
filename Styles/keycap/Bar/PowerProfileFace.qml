import QtQuick
import "../KeycapStyle.js" as KeycapStyle

// Power profile: a gear-shift key. Three dots under the icon (saver,
// balanced, performance); the lit one slides with a springy hop.
KeycapFace {
  id: face

  readonly property int gear: KeycapStyle.profileDot(faceData.profile)

  ownsIcon: true
  sink: key.y + key.faceY

  FaceKey {
    id: key
    face: face

    FaceGlyph {
      kit: face.kit
      anchors.horizontalCenter: parent.horizontalCenter
      y: Math.round(key.height * 0.12)
      height: key.height * 0.6
      icon: face.host ? face.host.icon : ""
      size: face.host && face.host.buttonSize ? face.host.buttonSize * 0.38 : 8
      color: face.kit.fillText
    }

    Row {
      id: dots
      anchors.horizontalCenter: parent.horizontalCenter
      y: key.height - height - face.kit.outline - 2
      spacing: Math.max(1, Math.round(key.width / 14))
      Repeater {
        model: 3
        Rectangle {
          required property int index
          width: Math.max(2, Math.round(key.width / 9))
          height: width
          radius: width / 2
          color: face.kit.mix(face.kit.fill, face.kit.ink, 0.35)
        }
      }
    }

    Rectangle {
      readonly property real dot: Math.max(2, Math.round(key.width / 9))
      width: dot + 2
      height: dot + 2
      radius: width / 2
      y: dots.y - 1
      x: dots.x - 1 + face.gear * (dot + dots.spacing)
      color: face.gear === 2 ? face.kit.error : (face.gear === 0 ? face.kit.secondary : face.kit.primary)
      border.color: face.kit.ink
      border.width: 1

      Behavior on x {
        NumberAnimation {
          duration: face.kit.normal
          easing.type: Easing.OutBack
          easing.overshoot: face.kit.popOvershoot
        }
      }
    }
  }
}
