import QtQuick
import qs.Commons

// Rounded group container using the variant surface color, drawn by the style's
// Box skin (Styles/<style>/Box.qml).
// To be used in side panels and settings panes to group fields or buttons.
// Opacity is based on panelBackgroundOpacity but clamped to a minimum to avoid full transparency.

Item {
  id: root

  property color color: ShellColors.mSurfaceVariant
  property bool forceOpaque: false
  property alias radius: shape.radius
  property alias border: shape.border

  NStyleSkin {
    id: skin
    name: "Box"
    control: root
  }

  // Only holds the shape settings for the skin
  Rectangle {
    id: shape
    visible: false
    radius: Style.radiusM
    border.color: skin.loaded ? skin.item.defaultBorderColor : Style.boxBorderColor
    border.width: Style.boxBorderWidth
  }
}
