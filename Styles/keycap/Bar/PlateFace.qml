import QtQuick

// Plain keycap. The deliberate exception: Tray, custom buttons and widgets
// without a face of their own sit on this.
KeycapFace {
  id: face

  sink: key.y + key.faceY

  FaceKey {
    id: key
    face: face
    fillColor: face.host && face.host.customBackgroundColor !== undefined && face.host.customBackgroundColor.a > 0 ? face.host.customBackgroundColor : face.kit.fill
  }
}
