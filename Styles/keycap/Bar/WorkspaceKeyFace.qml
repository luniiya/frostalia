import QtQuick
import "../KeycapStyle.js" as KeycapStyle

// One workspace in the key bed: the focused workspace is a wide raised key,
// occupied ones are chunky low dots, urgent ones bounce, and empty ones are
// hollow rings sitting flat in the bed. faceData carries the state and the
// colors resolved from the widget settings.
KeycapFace {
  id: face

  readonly property var look: KeycapStyle.workspaceKey(!!faceData.focused, !!faceData.urgent, !!faceData.occupied)
  readonly property color keyColor: {
    switch (look.kind) {
    case "focused":
      return faceData.focusedColor !== undefined ? faceData.focusedColor : kit.primary;
    case "urgent":
      return kit.error;
    case "occupied":
      return faceData.occupiedColor !== undefined ? faceData.occupiedColor : kit.secondary;
    default:
      return faceData.emptyColor !== undefined ? faceData.emptyColor : kit.surfaceVariantText;
    }
  }

  sink: look.hollow ? 0 : key.y + key.faceY
  onLookChanged: {
    if (look.kind === "urgent" || look.kind === "focused")
      bump();
  }

  FaceKey {
    id: key
    face: face
    visible: !face.look.hollow
    radius: height / 2
    depth: Math.max(1, Math.round(face.depth * face.look.depthScale))
    fillColor: face.keyColor
  }

  // Empty workspace: a hollow ring flat in the bed
  Rectangle {
    visible: face.look.hollow
    anchors.centerIn: parent
    width: Math.round(Math.min(parent.width, parent.height) * 0.62)
    height: width
    radius: width / 2
    color: "transparent"
    border.color: face.kit.mix(face.keyColor, face.kit.cream, 0.3)
    border.width: Math.max(1, face.kit.outline)
    scale: face.hovered ? 1.15 : 1

    Behavior on scale {
      NumberAnimation {
        duration: face.kit.fast
        easing.type: Easing.OutBack
        easing.overshoot: face.kit.popOvershoot
      }
    }
  }
}
