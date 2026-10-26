import QtQuick
import "../../../../Helpers/KeycapStyle.js" as KeycapStyle

// Brightness: a round dial key on a flat tab, ringed by eight sun-ray dots
// that light up with the level.
KeycapFace {
  id: face

  readonly property real level: faceData.level !== undefined ? faceData.level : 0
  readonly property int lit: KeycapStyle.levelSegments(level, 8)
  readonly property rect slot: host && host.iconRect ? host.iconRect : Qt.rect(0, 0, width, height)

  sink: dialSlot.y - face.slot.y + dial.y + dial.faceY

  // Tab under the revealed value
  FaceKey {
    face: face
    depth: Math.max(1, face.depth - 1)
    visible: face.width > face.slot.width + 1 || face.height > face.slot.height + 1
  }

  Item {
    id: dialSlot
    x: face.slot.x
    y: face.slot.y
    width: face.slot.width
    height: face.slot.height

    FaceKey {
      id: dial
      face: face
      radius: height / 2
      fillColor: face.kit.mix(face.kit.fill, face.kit.cream, 0.18)

      Repeater {
        model: 8
        Rectangle {
          required property int index
          readonly property real angle: index / 8 * 2 * Math.PI - Math.PI / 2
          readonly property real orbit: dial.width / 2 - face.kit.outline - width
          width: Math.max(2, Math.round(dial.width / 11))
          height: width
          radius: width / 2
          x: dial.width / 2 + Math.cos(angle) * orbit - width / 2
          y: dial.height / 2 + Math.sin(angle) * orbit - height / 2
          color: index < face.lit ? face.kit.tertiary : "transparent"
          border.color: face.kit.mix(face.kit.fill, face.kit.ink, 0.4)
          border.width: index < face.lit ? 0 : 1
          scale: index < face.lit ? 1 : 0.75

          Behavior on scale {
            NumberAnimation {
              duration: face.kit.fast
              easing.type: Easing.OutBack
              easing.overshoot: face.kit.popOvershoot
            }
          }
        }
      }
    }
  }
}
