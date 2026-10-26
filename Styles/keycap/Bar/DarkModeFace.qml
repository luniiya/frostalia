import QtQuick

// Dark mode: a two-tone key split down the middle, cream on one side and ink
// on the other. The icon is printed across the split in inverted colors.
// The dark half follows the current mode.
KeycapFace {
  id: face

  readonly property bool dark: faceData.dark !== undefined ? !!faceData.dark : true
  readonly property real inset: kit.outline
  readonly property real half: Math.round(width / 2)

  ownsIcon: true
  sink: key.y + key.faceY

  FaceKey {
    id: key
    face: face
    fillColor: face.kit.cream

    Repeater {
      model: 2
      Item {
        id: halfItem
        required property int index
        readonly property bool darkSide: (index === 1) === face.dark
        x: index === 0 ? face.inset : face.half
        y: face.inset
        width: index === 0 ? face.half - face.inset : key.width - face.half - face.inset
        height: key.height - 2 * face.inset
        clip: true

        Rectangle {
          x: halfItem.index === 0 ? 0 : -radius
          width: parent.width + radius
          height: parent.height
          radius: Math.max(0, key.radius - face.inset)
          color: halfItem.darkSide ? face.kit.shade : face.kit.cream
        }

        FaceGlyph {
          kit: face.kit
          icon: face.host ? face.host.icon : "dark-mode"
          size: face.host && face.host.buttonSize ? face.host.buttonSize * 0.46 : 9
          color: halfItem.darkSide ? face.kit.cream : face.kit.shade
          x: key.width / 2 - width / 2 - halfItem.x
          y: key.height / 2 - height / 2 - halfItem.y
        }
      }
    }
  }
}
