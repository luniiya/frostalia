import QtQuick
import "../../../Helpers/WeatherWidget.js" as WeatherWidget
import qs.Commons
import qs.Modules.DesktopWidgets
import qs.Modules.Weather

// Daily forecast as rows with range bars, or a compact strip.
DraggableDesktopWidget {
  id: root

  readonly property real padding: Math.round(Style.marginM * widgetScale)

  implicitWidth: Math.round(WeatherWidget.desktopSize("WeatherDaily", daily.compact).width * widgetScale)
  implicitHeight: daily.implicitHeight + padding * 2
  width: implicitWidth
  height: implicitHeight

  WeatherDaily {
    id: daily
    anchors.fill: parent
    anchors.margins: root.padding
    scaleFactor: root.widgetScale
    count: root.widgetSetting("days") ?? 7
    compact: root.widgetSetting("compact") ?? false
    showPrecipitation: root.widgetSetting("showPrecipitation") ?? true
  }
}
