import QtQuick
import qs.Commons

// A drawing of the bar for the card; the real bar can't be shrunk
Item {
  id: root

  property string screenName: ""

  readonly property string position: Settings.getBarPositionForScreen(screenName)
  readonly property bool vertical: position === "left" || position === "right"
  readonly property real thickness: Style.getBarHeightForScreen(screenName)
  readonly property bool floating: Settings.data.bar.barType === "floating"
  readonly property real marginH: floating ? Settings.data.bar.marginHorizontal : 0
  readonly property real marginV: floating ? Settings.data.bar.marginVertical : 0

  Rectangle {
    id: strip
    color: Qt.alpha(ShellColors.mSurface, 0.92)
    radius: root.floating ? Style.radiusL : 0
    x: root.position === "right" ? root.width - width - root.marginH : root.marginH
    y: root.position === "bottom" ? root.height - height - root.marginV : root.marginV
    width: root.vertical ? root.thickness : root.width - 2 * root.marginH
    height: root.vertical ? root.height - 2 * root.marginV : root.thickness

    // A few capsules so it reads as a bar
    Repeater {
      model: 7
      Rectangle {
        required property int index
        readonly property real size: root.thickness * 0.55
        width: root.vertical ? size : size * 1.6
        height: root.vertical ? size * 1.6 : size
        radius: Math.min(width, height) / 2
        color: ShellColors.mSurfaceVariant
        x: root.vertical ? (strip.width - width) / 2 : strip.width * 0.3 + index * (width + size * 0.5) - (index > 3 ? 0 : 0)
        y: root.vertical ? strip.height * 0.3 + index * (height + size * 0.5) : (strip.height - height) / 2
        visible: root.vertical ? y + height < strip.height : x + width < strip.width
      }
    }
  }
}
