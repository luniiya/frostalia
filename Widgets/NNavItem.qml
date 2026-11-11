import QtQuick
import qs.Commons

// Background of a navigation row (settings rail, search results), drawn by the
// style's skin (Styles/<style>/NavItem.qml). Content laid over it follows
// `contentOffset`, so it rides on a face that sinks when pressed or selected.
Item {
  id: root

  property bool selected: false
  property bool hovered: false
  property bool pressed: false
  property real radius: height / 2

  readonly property real contentOffset: skin.loaded && skin.item.sink !== undefined ? skin.item.sink : 0

  NStyleSkin {
    id: skin
    name: "NavItem"
    control: root
  }
}
