import QtQuick
import "../../Helpers/BubbleLogic.js" as BubbleLogic

MouseArea {
  id: root
  property int widgetCount: 0
  property real accumulator: 0
  signal cycleRequested(int step)

  enabled: widgetCount > 1
  anchors.fill: parent
  z: 1000
  acceptedButtons: Qt.NoButton
  onWidgetCountChanged: accumulator = 0
  onWheel: event => {
    event.accepted = true;
    var pixel = event.pixelDelta.x !== 0 || event.pixelDelta.y !== 0;
    var result = BubbleLogic.wheelStep(accumulator, pixel ? event.pixelDelta.x : event.angleDelta.x, pixel ? event.pixelDelta.y : event.angleDelta.y, pixel);
    accumulator = result.accumulator;
    if (result.step)
      cycleRequested(result.step);
  }
}
