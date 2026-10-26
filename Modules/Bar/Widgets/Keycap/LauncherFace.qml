import QtQuick
import QtQuick.Shapes

// Launcher: the big start key. Primary colored, with a cream sparkle on its
// corner that spins when you hover.
KeycapFace {
  id: face

  ownsIcon: true
  sink: key.y + key.faceY

  FaceKey {
    id: key
    face: face
    fillColor: face.kit.primary

    FaceGlyph {
      kit: face.kit
      anchors.centerIn: parent
      icon: face.host ? face.host.icon : ""
      size: face.host && face.host.buttonSize ? face.host.buttonSize * 0.46 : 9
      color: face.kit.primaryText
    }
  }

  Shape {
    id: sparkle
    readonly property real s: Math.max(6, Math.round(face.height * 0.36))
    z: 2
    width: s
    height: s
    x: face.width - s * 0.7
    y: face.centerShift + key.faceY - s * 0.3
    rotation: face.hovered ? 90 : 0
    scale: face.pop
    preferredRendererType: Shape.CurveRenderer

    Behavior on rotation {
      NumberAnimation {
        duration: face.kit.slow
        easing.type: Easing.OutBack
        easing.overshoot: face.kit.popOvershoot
      }
    }

    ShapePath {
      strokeWidth: 1
      strokeColor: face.kit.ink
      fillColor: face.kit.cream
      joinStyle: ShapePath.RoundJoin
      startX: sparkle.s / 2
      startY: 0
      PathQuad {
        x: sparkle.s
        y: sparkle.s / 2
        controlX: sparkle.s * 0.58
        controlY: sparkle.s * 0.42
      }
      PathQuad {
        x: sparkle.s / 2
        y: sparkle.s
        controlX: sparkle.s * 0.58
        controlY: sparkle.s * 0.58
      }
      PathQuad {
        x: 0
        y: sparkle.s / 2
        controlX: sparkle.s * 0.42
        controlY: sparkle.s * 0.58
      }
      PathQuad {
        x: sparkle.s / 2
        y: 0
        controlX: sparkle.s * 0.42
        controlY: sparkle.s * 0.42
      }
    }
  }
}
