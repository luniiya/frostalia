import QtQuick

// Workspaces, background: a recessed key bed the workspace keys sit in.
// Darker than the bar keys, with an inner shade along the top edge and no
// drop shadow, so it reads as sunk into the bar.
KeycapFace {
  id: face

  Rectangle {
    id: bed
    anchors.fill: parent
    radius: Math.min(face.kit.radius, height / 2)
    color: face.kit.mix(face.kit.fill, face.kit.ink, 0.3)
    border.color: face.kit.ink
    border.width: face.kit.outline
    scale: face.pop

    // Inner shade: the bed's top wall
    Rectangle {
      x: face.kit.outline
      y: face.kit.outline
      width: parent.width - 2 * face.kit.outline
      height: Math.max(2, face.depth)
      topLeftRadius: Math.max(0, bed.radius - face.kit.outline)
      topRightRadius: Math.max(0, bed.radius - face.kit.outline)
      color: face.kit.ink
      opacity: 0.45
    }
  }
}
