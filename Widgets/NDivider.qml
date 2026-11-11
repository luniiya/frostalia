import QtQuick
import qs.Commons

// A separator line drawn by the style's skin (Styles/<style>/Divider.qml), which
// also picks its thickness.
Item {
  id: root

  property bool vertical: false

  readonly property real thickness: skin.loaded && skin.item.thickness !== undefined ? skin.item.thickness : Style.borderS

  width: vertical ? thickness : parent.width
  height: vertical ? parent.height : thickness
  implicitWidth: vertical ? thickness : 0
  implicitHeight: vertical ? 0 : thickness

  NStyleSkin {
    id: skin
    name: "Divider"
    control: root
  }
}
