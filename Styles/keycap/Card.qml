import QtQuick
import QtQuick.Effects
import "KeycapStyle.js" as KeycapStyle
import qs.Commons

// NStyleCard: the card gets an ink outline, a thin cream keyline and a hard shadow
// straight down. The card's fill must be opaque, or the shadow shows through it.
// Clickable cards lift off their shadow on hover and sink into it while pressed;
// the shadow stays in place. Keycap skins also use it directly inside a Rectangle.
Item {
  id: root

  // The NStyleCard that loaded this skin, if any; it sits inside the card
  property Item control
  readonly property var kit: Style.kitFor("Styles/keycap/Kit.qml")
  readonly property Item card: control ? control.parent : parent
  readonly property bool active: card !== null
  property real depth: kit.depth
  readonly property bool hovered: control ? control.hovered : false
  readonly property bool pressed: control ? control.pressed : false

  // Face offset from rest: negative while lifted, positive while sunk
  property real sink: active ? KeycapStyle.sink(depth, kit.pressedDepth, kit.hoverLift, pressed, hovered) : 0
  Behavior on sink {
    NumberAnimation {
      duration: root.pressed ? Math.round(Style.animationFast / 2) : Style.animationFast
      easing.type: root.pressed ? Easing.OutQuad : Easing.OutBack
      easing.overshoot: root.kit.overshoot
    }
  }

  Translate {
    id: lift
    y: root.sink
  }

  anchors.fill: control ? undefined : parent
  // Under the card's other children, so content stays on top of the keyline
  z: -1

  Rectangle {
    anchors.fill: parent
    anchors.margins: root.kit.outline
    radius: Math.max(0, (root.card ? root.card.radius : 0) - root.kit.outline)
    color: "transparent"
    border.color: root.kit.ringFor(root.card ? root.card.color : root.kit.surface)
    border.width: root.kit.ring
  }

  Binding {
    when: root.active
    target: root.card
    property: "border.color"
    value: root.kit.ink
  }
  Binding {
    when: root.active
    target: root.card
    property: "border.width"
    value: root.kit.outline
  }
  Binding {
    when: root.active
    target: root.card
    property: "transform"
    value: [lift]
  }
  Binding {
    when: root.active && root.depth > 0
    target: root.card
    property: "layer.enabled"
    value: true
  }
  Binding {
    when: root.active && root.depth > 0
    target: root.card
    property: "layer.effect"
    value: shadowEffect
  }

  // Unblurred, fully opaque drop shadow: a copy of the card's shape `depth` px lower
  Component {
    id: shadowEffect
    MultiEffect {
      shadowEnabled: true
      shadowBlur: 0
      shadowOpacity: 1
      shadowColor: root.kit.ink
      shadowHorizontalOffset: 0
      // The shadow stays where it was while the face moves
      shadowVerticalOffset: root.depth - root.sink
      autoPaddingEnabled: true
    }
  }
}
