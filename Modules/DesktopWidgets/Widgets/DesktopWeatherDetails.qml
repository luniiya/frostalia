import QtQuick
import "../../../Helpers/WeatherWidget.js" as WeatherWidget
import qs.Commons
import qs.Modules.DesktopWidgets
import qs.Modules.Weather

// One selected weather detail tile, independent of the forecast widget.
DraggableDesktopWidget {
  id: root
  horizontalResizable: true
  verticalResizable: false

  readonly property real padding: Math.round(DesktopMetrics.marginM * widgetScale)
  readonly property var baseSize: WeatherWidget.desktopSize("detail")
  implicitWidth: Math.round(baseSize.width * widgetScale)
  implicitHeight: Math.round(baseSize.height * widgetScale)

  WeatherDetailTile {
    anchors.fill: parent
    anchors.margins: root.padding
    scaleFactor: root.widgetScale
    kind: root.widgetSetting("detail") ?? "wind"
  }
}
