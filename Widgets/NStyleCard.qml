import QtQuick
import qs.Commons

// Style dressing for a card of the shared layouts: put it inside the card (a
// Rectangle) as its first child. The style's Card skin (Styles/<style>/Card.qml)
// may restyle the card's border and add an effect under it; Material leaves the
// card alone. The card's fill must be opaque in styles with `opaqueSurfaces`.
// Bind `hovered` / `pressed` on clickable cards.
NStyleSkin {
  id: root

  property bool hovered: false
  property bool pressed: false

  name: "Card"
  control: root
  // Under the card's other children, so content stays on top
  z: -1
}
