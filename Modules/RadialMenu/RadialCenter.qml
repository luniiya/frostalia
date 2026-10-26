import QtQuick
import qs.Commons
import qs.Services.UI
import qs.Widgets

// Center of the ring: names the hovered item, otherwise offers back (nested rings) or
// close. Clicking it goes up a level. A disc for most styles, an outlined keycap with a
// hard shadow for chunky ones.
Item {
  id: root

  required property var ring

  readonly property var spec: ring.spec
  readonly property real s: ring.s
  readonly property bool chunky: spec.shape === "chunky"
  readonly property real size: spec.centerRadius * 2 * s
  readonly property real cornerRadius: spec.centerShape === "squircle" ? size * 0.32 : size / 2
  readonly property string label: ring.hoveredItem ? RadialMenuService.labelFor(ring.hoveredItem) : ""

  property real appear: 0
  NumberAnimation on appear {
    to: 1
    duration: Style.animationNormal
    easing.type: Easing.OutBack
  }
  scale: 0.5 + 0.5 * appear
  opacity: appear

  // Hard shadow
  Rectangle {
    visible: root.spec.shadowOpacity > 0
    x: -root.size / 2 + root.spec.shadowX * root.s
    y: -root.size / 2 + root.spec.shadowY * root.s
    width: root.size
    height: root.size
    radius: root.cornerRadius
    color: root.ring.color(root.spec.colors.shadow)
    opacity: root.spec.shadowOpacity
  }

  Rectangle {
    id: disc
    x: -root.size / 2
    y: -root.size / 2
    width: root.size
    height: root.size
    radius: root.cornerRadius
    color: Qt.alpha(root.ring.color(root.spec.colors.center), root.spec.fillOpacity)
    border.width: root.spec.borderWidth > 0 ? root.spec.borderWidth * root.s : (root.spec.shape === "orbit" ? Math.max(1, Style.borderS) : 0)
    border.color: root.spec.shape === "orbit" ? Qt.alpha(root.ring.color(root.spec.colors.track), 0.5) : root.ring.color(root.spec.colors.outline)

    // Keyline inside the outline (keycap stickers)
    Rectangle {
      readonly property real keyline: root.spec.borderWidth > 0 ? root.spec.keylineWidth * root.s : 0
      visible: keyline > 0
      anchors.fill: parent
      anchors.margins: disc.border.width
      radius: Math.max(0, disc.radius - disc.border.width)
      color: "transparent"
      border.width: keyline
      border.color: root.ring.color(root.spec.colors.keyline)
    }

    NText {
      anchors.centerIn: parent
      width: parent.width - Style.marginS * 2
      visible: root.label !== ""
      text: root.chunky ? root.label.toUpperCase() : root.label
      horizontalAlignment: Text.AlignHCenter
      wrapMode: Text.Wrap
      maximumLineCount: 2
      elide: Text.ElideRight
      pointSize: Style.fontSizeS
      font.weight: root.chunky ? Style.fontWeightBold : Style.fontWeightMedium
      font.letterSpacing: root.chunky ? 0.6 : 0
      color: root.ring.color(root.spec.colors.onCenter)
    }

    NIcon {
      anchors.centerIn: parent
      visible: root.label === ""
      icon: root.ring.nested ? "arrow-back-up" : "x"
      pointSize: Style.fontSizeL
      color: Qt.alpha(root.ring.color(root.spec.colors.onCenter), 0.7)
    }
  }
}
