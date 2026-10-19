import QtQuick
import QtQuick.Layouts
import "../../../Helpers/WeatherWidget.js" as WeatherWidget
import qs.Commons
import qs.Modules.DesktopWidgets
import qs.Modules.Weather
import qs.Services.Location

// Current conditions on the shared widget background (or the animated sky),
// optionally with a daily strip.
DraggableDesktopWidget {
  id: root

  readonly property int forecastDays: widgetSetting("forecastDays") ?? 0
  readonly property real padding: Math.round(Style.marginM * widgetScale)

  implicitWidth: Math.round(WeatherWidget.desktopSize("Weather").width * widgetScale)
  implicitHeight: column.implicitHeight
  width: implicitWidth
  height: implicitHeight

  ColumnLayout {
    id: column
    width: parent.width
    spacing: 0

    WeatherCurrent {
      Layout.fillWidth: true
      Layout.preferredHeight: implicitHeight
      scaleFactor: root.widgetScale
      padding: root.padding
      badgeSize: Math.round(64 * root.widgetScale)
      temperatureSize: Style.fontSizeXXXL * 1.5 * root.widgetScale
      radius: root.backgroundRadius
      showSky: root.widgetSetting("animatedSky") ?? false
      showCondition: root.widgetSetting("showCondition") ?? true
      showHighLow: root.widgetSetting("showHighLow") ?? true
      showFeelsLike: root.widgetSetting("showFeelsLike") ?? true
    }

    WeatherDaily {
      Layout.fillWidth: true
      Layout.leftMargin: root.padding
      Layout.rightMargin: root.padding
      Layout.bottomMargin: root.padding
      visible: root.forecastDays > 0 && LocationService.weatherReady
      compact: true
      showTitle: false
      count: root.forecastDays
      scaleFactor: root.widgetScale
    }
  }
}
