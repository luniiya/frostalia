import QtQuick
import "../../../../Helpers/KeycapStyle.js" as KeycapStyle

// Volume: a keycap you can watch sink. Muting latches it down; five ticks
// engraved under the speaker show the level and hop when it changes.
KeycapFace {
  id: face

  readonly property real level: faceData.level !== undefined ? faceData.level : 0
  readonly property bool muted: !!faceData.muted
  readonly property int lit: muted ? 0 : KeycapStyle.levelSegments(level, 5)
  readonly property rect slot: host && host.iconRect ? host.iconRect : Qt.rect(0, 0, width, height)

  sink: key.y + key.faceY
  onLitChanged: tickHop.restart()

  FaceKey {
    id: key
    face: face
    latched: face.muted
    fillColor: face.muted ? face.kit.mix(face.kit.fill, face.kit.ink, 0.25) : face.kit.fill

    Row {
      x: face.slot.x + (face.slot.width - width) / 2
      y: face.slot.y + face.slot.height - height - Math.max(2, face.kit.outline + 1)
      height: Math.max(3, Math.round(face.slot.height / 9) + 1)
      spacing: 1

      transform: Translate {
        id: hop
      }

      Repeater {
        model: 5
        Rectangle {
          required property int index
          width: Math.max(1, Math.round(face.slot.width / 14))
          height: parent.height - (index < face.lit ? 0 : 1)
          y: parent.height - height
          radius: width / 2
          color: index < face.lit ? face.kit.primary : face.kit.mix(face.kit.fill, face.kit.ink, 0.35)
        }
      }
    }
  }

  SequentialAnimation {
    id: tickHop
    NumberAnimation {
      target: hop
      property: "y"
      to: -1.5
      duration: Math.round(face.kit.fast / 2)
    }
    NumberAnimation {
      target: hop
      property: "y"
      to: 0
      duration: face.kit.fast
      easing.type: Easing.OutBack
      easing.overshoot: face.kit.overshoot
    }
  }
}
