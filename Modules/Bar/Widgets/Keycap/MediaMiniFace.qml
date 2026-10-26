import QtQuick
import "../../../../Helpers/KeycapStyle.js" as KeycapStyle

// Media: a ticket stub. Notches are cut into both edges after the first
// square (the art), with a dashed perforation line between them.
KeycapFace {
  id: face

  readonly property bool vertical: !!(host && host.isVertical)

  FaceKey {
    visible: face.vertical
    face: face
  }

  FaceShape {
    id: ticket
    visible: !face.vertical
    face: face
    readonly property real notchX: Math.min(width / 2, height)
    pathFor: (w, h) => KeycapStyle.ticketPath(w, h, Math.min(face.kit.smallRadius, h / 2), Math.min(w / 2, h), Math.max(2, Math.round(h * 0.16)))

    Column {
      x: ticket.notchX
      y: Math.round(ticket.height * 0.22)
      spacing: 2
      Repeater {
        model: Math.max(1, Math.floor(ticket.height * 0.56 / 4))
        Rectangle {
          width: 1
          height: 2
          color: face.kit.ink
          opacity: 0.6
        }
      }
    }
  }
}
