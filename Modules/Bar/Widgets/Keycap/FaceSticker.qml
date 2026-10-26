import QtQuick

// Die-cut sticker: a cream cut margin around a colored body, an ink outline
// and a hard shadow, stuck on slightly tilted. Pressing flattens it.
Item {
  id: sticker

  required property var face
  default property alias content: body.data

  property color bodyColor: face.kit.fill
  property real cut: Math.max(2, face.kit.outline + 1)
  property real radius: Math.min(face.kit.radius, height / 2)
  // Tilt in degrees; derive it from a seed with KeycapStyle.tilt().
  property real tilt: 0

  readonly property real sinkY: face.pressed ? Math.max(0, face.depth - face.kit.pressedDepth) : (face.hovered ? -face.kit.hoverLift : 0)
  readonly property Item body: body
  // Animated plate offset, for content drawn outside the sticker
  readonly property real faceY: plate.y

  width: parent ? parent.width : 0
  height: parent ? parent.height : 0
  y: face.centerShift
  scale: face.pop
  rotation: face.hovered ? 0 : tilt

  Behavior on rotation {
    NumberAnimation {
      duration: sticker.face.kit.normal
      easing.type: Easing.OutBack
      easing.overshoot: sticker.face.kit.overshoot
    }
  }

  Rectangle {
    y: sticker.face.depth
    width: parent.width
    height: parent.height
    radius: sticker.radius
    color: sticker.face.kit.ink
    visible: sticker.face.depth > 0
  }

  Rectangle {
    id: plate
    y: sticker.sinkY
    width: parent.width
    height: parent.height
    radius: sticker.radius
    color: sticker.face.kit.cream
    border.color: sticker.face.kit.ink
    border.width: sticker.face.kit.outline

    Behavior on y {
      NumberAnimation {
        duration: sticker.face.pressed ? Math.round(sticker.face.kit.fast / 2) : sticker.face.kit.fast
        easing.type: sticker.face.pressed ? Easing.OutQuad : Easing.OutBack
        easing.overshoot: sticker.face.kit.overshoot
      }
    }

    Rectangle {
      id: body
      anchors.fill: parent
      anchors.margins: sticker.cut
      radius: Math.max(0, sticker.radius - sticker.cut)
      color: sticker.bodyColor

      Behavior on color {
        ColorAnimation {
          duration: sticker.face.kit.fast
        }
      }
    }
  }
}
