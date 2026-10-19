import QtQuick
import "../../../Helpers/WeatherWidget.js" as WeatherWidget
import qs.Commons
import qs.Modules.DesktopWidgets
import qs.Modules.Weather

// A single weather detail tile (wind, UV, humidity, ...).
DraggableDesktopWidget {
  id: root

  readonly property real padding: Math.round(Style.marginM * widgetScale)

  implicitWidth: Math.round(WeatherWidget.desktopSize("WeatherDetail").width * widgetScale)
  implicitHeight: Math.round(WeatherWidget.desktopSize("WeatherDetail").height * widgetScale)
  width: implicitWidth
  height: implicitHeight

  WeatherDetailTile {
    anchors.fill: parent
    anchors.margins: root.padding
    scaleFactor: root.widgetScale
    kind: root.widgetSetting("detail") ?? "wind"
  }
}
