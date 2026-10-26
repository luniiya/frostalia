import QtQuick
import "../KeycapStyle.js" as KeycapStyle

// Active window: a strip of embossed label tape with fishtail-cut ends,
// like a label-maker name tag for the focused window.
KeycapFace {
  id: face

  readonly property bool vertical: !!(host && host.isVerticalBar)

  FaceKey {
    visible: face.vertical
    face: face
  }

  FaceShape {
    id: tape
    visible: !face.vertical
    face: face
    pathFor: (w, h) => KeycapStyle.tapePath(w, h, Math.round(h * 0.28))

    // Embossed sheen line
    Rectangle {
      x: Math.round(tape.height * 0.4)
      y: face.kit.outline + 2
      width: Math.max(0, tape.width - 2 * x)
      height: 1
      color: face.kit.cream
      opacity: 0.45
    }
  }
}
