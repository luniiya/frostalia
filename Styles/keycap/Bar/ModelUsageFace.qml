import QtQuick
import "../KeycapStyle.js" as KeycapStyle

// Model usage: a till receipt with a torn zig-zag bottom edge.
KeycapFace {
  id: face

  readonly property bool vertical: !!(host && host.isVertical)

  sink: receipt.y + receipt.faceY

  FaceShape {
    id: receipt
    face: face
    fillColor: face.kit.mix(face.kit.fill, face.kit.cream, 0.08)
    pathFor: (w, h) => KeycapStyle.receiptPath(w, h, Math.min(face.kit.smallRadius, h / 3), Math.max(1.5, Math.round(Math.min(w, h) / 10)))
  }
}
