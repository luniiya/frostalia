import QtQuick

// Plain keycap. The deliberate exception: Tray, custom buttons and widgets
// without a face of their own sit on this. Plugins set faceData.hoverFill: they
// color their content for the hover color while hovered, and their own capsule
// (which would show it) is cleared, so the plate takes it instead.
KeycapFace {
  id: face

  sink: key.y + key.faceY

  FaceKey {
    id: key
    face: face
    fillColor: face.faceData.hoverFill && face.hovered ? face.kit.hover : face.host && face.host.customBackgroundColor !== undefined && face.host.customBackgroundColor.a > 0 ? face.host.customBackgroundColor : face.kit.fill
  }
}
