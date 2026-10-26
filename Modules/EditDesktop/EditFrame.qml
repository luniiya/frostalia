import QtQuick
import qs.Commons

// Rings around the card. They are thick enough to hide the square corners of the card's content,
// which gives it rounded corners without clipping.
Item {
  id: root

  // The card, in screen coordinates
  property real cardX: 0
  property real cardY: 0
  property real cardWidth: 0
  property real cardHeight: 0
  property color stageColor: Qt.darker(ShellColors.mSurface, 3)
  property real corner: 22
  property real cover: 12
  property real ring: 3

  // Covers the corners of the card, the same color as the stage
  Rectangle {
    x: root.cardX - root.cover
    y: root.cardY - root.cover
    width: root.cardWidth + 2 * root.cover
    height: root.cardHeight + 2 * root.cover
    radius: root.corner + root.cover
    color: "transparent"
    border.width: root.cover
    border.color: root.stageColor
  }

  // The visible ring on the card's edge
  Rectangle {
    x: root.cardX - root.ring
    y: root.cardY - root.ring
    width: root.cardWidth + 2 * root.ring
    height: root.cardHeight + 2 * root.ring
    radius: root.corner + root.ring
    color: "transparent"
    border.width: root.ring
    border.color: ShellColors.mPrimary
  }
}
