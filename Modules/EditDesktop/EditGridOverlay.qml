import QtQuick
import "../../Helpers/DesktopWidgetEdit.js" as WidgetEdit
import qs.Commons

// The snap grid, drawn on the card
Canvas {
  id: root

  property real screenWidth: width
  property real screenHeight: height
  readonly property int gridSize: WidgetEdit.gridSize(screenWidth, screenHeight)

  opacity: 0.25

  onPaint: {
    const ctx = getContext("2d");
    ctx.reset();
    ctx.strokeStyle = ShellColors.mPrimary;
    ctx.lineWidth = 1;
    for (let x = 0; x <= width; x += gridSize) {
      ctx.beginPath();
      ctx.moveTo(x, 0);
      ctx.lineTo(x, height);
      ctx.stroke();
    }
    for (let y = 0; y <= height; y += gridSize) {
      ctx.beginPath();
      ctx.moveTo(0, y);
      ctx.lineTo(width, y);
      ctx.stroke();
    }
  }

  onWidthChanged: requestPaint()
  onHeightChanged: requestPaint()
  onGridSizeChanged: requestPaint()
  Component.onCompleted: requestPaint()
}
