import QtQuick
import QtQuick.Shapes
import "../../../../Helpers/KeycapStyle.js" as KeycapStyle

// VPN: a luggage tag on a string. The tag fills with the tertiary color
// while a tunnel is up.
KeycapFace {
  id: face

  readonly property bool active: !!faceData.active

  sink: tag.y + tag.faceY
  contentColor: active ? kit.tertiaryText : "transparent"
  onActiveChanged: bump()

  // The string, looping out of the tag's point
  Shape {
    width: Math.round(face.height * 0.3)
    height: face.height
    x: -width + face.kit.outline
    y: face.centerShift
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      strokeWidth: Math.max(1, face.kit.outline - 0.5)
      strokeColor: face.kit.ink
      fillColor: "transparent"
      capStyle: ShapePath.RoundCap
      startX: face.height * 0.3
      startY: face.height / 2
      PathQuad {
        x: 0
        y: face.height * 0.15
        controlX: face.height * 0.02
        controlY: face.height * 0.55
      }
    }
  }

  FaceShape {
    id: tag
    face: face
    fillColor: face.active ? face.kit.tertiary : face.kit.fill
    pathFor: (w, h) => KeycapStyle.tagPath(w, h, Math.min(face.kit.smallRadius, h / 2), h * 0.28)
  }
}
