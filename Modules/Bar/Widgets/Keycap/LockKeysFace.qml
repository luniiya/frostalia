import QtQuick

// Lock keys: a key with a row of indicator LEDs along its top edge, one per
// shown lock (caps, num, scroll), lit while the lock is on.
KeycapFace {
  id: face

  // [{ "on": bool }, ...] for the locks the widget shows
  readonly property var leds: faceData.leds || []
  readonly property bool vertical: !!(host && host.isVertical)

  FaceKey {
    id: key
    face: face
    radius: Math.min(face.kit.smallRadius, Math.min(width, height) / 3)

    Grid {
      columns: face.vertical ? 1 : Math.max(1, face.leds.length)
      spacing: Math.max(2, Math.round(Math.min(key.width, key.height) / 6))
      x: face.vertical ? face.kit.outline + 1 : (key.width - width) / 2
      y: face.vertical ? (key.height - height) / 2 : face.kit.outline + 1

      Repeater {
        model: face.leds
        Rectangle {
          required property var modelData
          width: face.vertical ? Math.max(1, Math.round(face.kit.outline)) : Math.max(3, Math.round(key.width / Math.max(4, face.leds.length * 3)))
          height: face.vertical ? Math.max(3, Math.round(key.height / Math.max(4, face.leds.length * 3))) : Math.max(1, Math.round(face.kit.outline))
          radius: Math.min(width, height) / 2
          color: modelData.on ? face.kit.tertiary : face.kit.mix(face.kit.fill, face.kit.ink, 0.35)

          Behavior on color {
            ColorAnimation {
              duration: face.kit.fast
            }
          }
        }
      }
    }
  }
}
