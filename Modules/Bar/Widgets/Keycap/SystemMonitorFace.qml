import QtQuick

// System monitor: a recessed LCD plate. Sunk into the bar (inner shade, no
// drop shadow) with faint scanlines and a screw at each end.
KeycapFace {
  id: face

  readonly property bool vertical: !!(host && host.isVertical)

  Rectangle {
    id: plate
    anchors.fill: parent
    radius: Math.min(face.kit.smallRadius, Math.min(width, height) / 3)
    color: face.kit.surface
    border.color: face.kit.ink
    border.width: face.kit.outline
    scale: face.pop
    clip: true

    // Scanlines
    Column {
      x: face.kit.outline
      y: face.kit.outline
      spacing: 2
      Repeater {
        model: Math.max(0, Math.floor((plate.height - 2 * face.kit.outline) / 3))
        Rectangle {
          width: plate.width - 2 * face.kit.outline
          height: 1
          color: face.kit.ink
          opacity: 0.12
        }
      }
    }

    // Inner shade along the top wall
    Rectangle {
      x: face.kit.outline
      y: face.kit.outline
      width: parent.width - 2 * face.kit.outline
      height: Math.max(2, face.depth)
      color: face.kit.ink
      opacity: 0.35
    }

    // Screws
    Repeater {
      model: 2
      Rectangle {
        required property int index
        readonly property real edge: face.kit.outline + 2
        width: Math.max(2, Math.round(Math.min(plate.width, plate.height) / 9))
        height: width
        radius: width / 2
        x: face.vertical ? (plate.width - width) / 2 : (index === 0 ? edge : plate.width - width - edge)
        y: face.vertical ? (index === 0 ? edge : plate.height - height - edge) : (plate.height - height) / 2
        color: face.kit.mix(face.kit.surface, face.kit.cream, 0.35)
        border.color: face.kit.ink
        border.width: 1
      }
    }
  }
}
