import QtQuick
import "../KeycapStyle.js" as KeycapStyle

// Settings: a postage stamp with perforated edges. The gear turns a notch
// with a spring when you hover.
KeycapFace {
  id: face

  ownsIcon: true
  sink: stamp.y + stamp.faceY

  FaceShape {
    id: stamp
    face: face
    fillColor: face.kit.mix(face.kit.fill, face.kit.cream, 0.15)
    pathFor: (w, h) => KeycapStyle.stampPath(w, h, Math.max(1, Math.min(w, h) / 12))

    FaceGlyph {
      kit: face.kit
      anchors.centerIn: parent
      icon: face.host ? face.host.icon : "settings"
      size: face.host && face.host.buttonSize ? face.host.buttonSize * 0.44 : 9
      color: face.host && face.host.colorFg !== undefined ? face.host.colorFg : face.kit.fillText
      rotation: face.hovered ? 60 : 0

      Behavior on rotation {
        NumberAnimation {
          duration: face.kit.slow
          easing.type: Easing.OutBack
          easing.overshoot: face.kit.overshoot
        }
      }
    }
  }
}
