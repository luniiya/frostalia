import QtQuick
import qs.Commons

// Rounded group container using the variant surface color.
// To be used in side panels and settings panes to group fields or buttons.
// Opacity is based on panelBackgroundOpacity but clamped to a minimum to avoid full transparency.

Item {
  id: root

  property color color: ShellColors.mSurfaceVariant
  property bool forceOpaque: false
  property alias radius: bg.radius
  property alias border: bg.border

  // Keycap: boxes are cards with an ink outline, a cream ring and a hard shadow
  Rectangle {
    visible: Style.keycapControls
    width: bg.width
    height: bg.height
    y: Style.keycapDepth
    radius: bg.radius
    color: KeycapKit.ink
  }

  Rectangle {
    id: bg
    anchors.fill: parent
    radius: Style.radiusM
    border.color: Style.keycapControls && Settings.data.ui.boxBorderEnabled ? KeycapKit.ink : Style.boxBorderColor
    border.width: Style.boxBorderWidth

    Rectangle {
      visible: Style.keycapControls && bg.border.width > 0
      anchors.fill: parent
      anchors.margins: bg.border.width
      radius: Math.max(0, bg.radius - bg.border.width)
      color: "transparent"
      border.color: KeycapKit.ringFor(bg.color)
      border.width: Style.keycapRing
    }
    color: {
      // Keycap cards are solid so their shadow does not show through
      if (forceOpaque || Style.keycapControls) {
        return root.color;
      }

      return ShellColors.smartAlpha(root.color);
    }
  }
}
