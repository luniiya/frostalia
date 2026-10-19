import QtQuick
import "../../../Helpers/WeatherWidget.js" as WeatherWidget
import qs.Commons
import qs.Modules.DesktopWidgets
import qs.Modules.Weather

// Hourly temperature curve.
DraggableDesktopWidget {
  id: root

  readonly property real padding: Math.round(Style.marginM * widgetScale)

  implicitWidth: Math.round(WeatherWidget.desktopSize("WeatherHourly").width * widgetScale)
  implicitHeight: hourly.implicitHeight + padding * 2
  width: implicitWidth
  height: implicitHeight

  WeatherHourly {
    id: hourly
    anchors.fill: parent
    anchors.margins: root.padding
    scaleFactor: root.widgetScale
    count: root.widgetSetting("hours") ?? 12
    showPrecipitation: root.widgetSetting("showPrecipitation") ?? true
  }
}
