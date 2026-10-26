import QtQuick
import QtQuick.Effects
import qs.Commons

// Keycap skin for a Material card: put it inside the card (a Rectangle) as its first
// child. In the Keycap style the card gets an ink outline, a thin cream keyline and a
// hard shadow straight down; other styles are left alone. The card's fill must be
// opaque, or the shadow shows through it.
Item {
  id: root

  readonly property Item card: parent
  readonly property bool active: Style.keycapControls
  property real depth: Style.keycapDepth

  anchors.fill: parent
  // Under the card's other children, so content stays on top of the keyline
  z: -1
  visible: active

  Rectangle {
    anchors.fill: parent
    anchors.margins: Style.keycapOutline
    radius: Math.max(0, (root.card ? root.card.radius : 0) - Style.keycapOutline)
    color: "transparent"
    border.color: KeycapKit.ringFor(root.card ? root.card.color : KeycapKit.surface)
    border.width: Style.keycapRing
  }

  Binding {
    when: root.active
    target: root.card
    property: "border.color"
    value: KeycapKit.ink
  }
  Binding {
    when: root.active
    target: root.card
    property: "border.width"
    value: Style.keycapOutline
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
      shadowColor: KeycapKit.ink
      shadowHorizontalOffset: 0
      shadowVerticalOffset: root.depth
      autoPaddingEnabled: true
    }
  }
}
