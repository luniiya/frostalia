import QtQuick

// Audio visualizer: a speaker grille. A grid of punched dots sits behind the
// bars; the grille thumps (pops) when you click it.
KeycapFace {
  id: face

  readonly property real dot: Math.max(1, Math.round(height / 12))
  readonly property real pitch: dot * 3

  FaceKey {
    id: grille
    face: face
    radius: Math.min(face.kit.smallRadius, Math.min(width, height) / 3)

    Item {
      id: holes
      readonly property int columns: Math.max(1, Math.floor(width / face.pitch))
      readonly property int rows: Math.max(1, Math.floor(height / face.pitch))
      anchors.fill: parent
      anchors.margins: face.kit.outline + 2
      clip: true

      Grid {
        columns: holes.columns
        rows: holes.rows
        spacing: face.pitch - face.dot
        anchors.centerIn: parent
        Repeater {
          model: holes.columns * holes.rows
          Rectangle {
            width: face.dot
            height: face.dot
            radius: face.dot / 2
            color: face.kit.ink
            opacity: 0.22
          }
        }
      }
    }
  }
}
