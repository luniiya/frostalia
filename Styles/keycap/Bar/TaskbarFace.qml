import QtQuick

// Taskbar: a strip of film. Rows of sprocket holes run along the top and
// bottom edges; the app icons are the frames.
KeycapFace {
  id: face

  readonly property bool vertical: !!(host && host.isVerticalBar !== undefined ? host.isVerticalBar : (host && host.isVertical))

  FaceKey {
    id: strip
    face: face
    radius: Math.min(face.kit.smallRadius, Math.min(width, height) / 3)
    depth: Math.max(1, face.depth - 1)

    Repeater {
      model: 2
      Item {
        id: rail
        required property int index
        readonly property real hole: Math.max(2, Math.round(Math.min(strip.width, strip.height) / 11))
        readonly property real inset: face.kit.outline + 1
        x: face.vertical ? (index === 0 ? inset : strip.width - hole - inset) : inset
        y: face.vertical ? inset : (index === 0 ? inset : strip.height - hole - inset)
        width: face.vertical ? hole : strip.width - 2 * inset
        height: face.vertical ? strip.height - 2 * inset : hole
        clip: true

        Grid {
          rows: face.vertical ? Math.max(1, Math.floor(rail.height / (rail.hole * 2))) : 1
          columns: face.vertical ? 1 : Math.max(1, Math.floor(rail.width / (rail.hole * 2)))
          spacing: rail.hole
          x: face.vertical ? 0 : rail.hole / 2
          y: face.vertical ? rail.hole / 2 : 0
          Repeater {
            model: face.vertical ? Math.max(1, Math.floor(rail.height / (rail.hole * 2))) : Math.max(1, Math.floor(rail.width / (rail.hole * 2)))
            Rectangle {
              width: rail.hole
              height: rail.hole
              radius: 1
              color: face.kit.mix(face.kit.fill, face.kit.ink, 0.55)
            }
          }
        }
      }
    }
  }
}
