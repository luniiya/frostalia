import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Modules.Weather
import qs.Services.Location
import qs.Widgets

// Weather card for the control center and clock panel: current conditions over
// the animated sky and a compact daily strip.
NBox {
  id: root

  property int forecastDays: 6
  property bool showLocation: true

  readonly property real inset: Style.marginS

  visible: Settings.data.location.weatherEnabled
  implicitHeight: column.implicitHeight + inset * 2

  ColumnLayout {
    id: column
    anchors.fill: parent
    anchors.margins: root.inset
    spacing: Style.marginM

    WeatherCurrent {
      Layout.fillWidth: true
      Layout.preferredHeight: implicitHeight
      radius: Math.max(0, root.radius - root.inset)
      showLocation: root.showLocation && !Settings.data.location.hideWeatherCityName
      showFeelsLike: false
    }

    WeatherDaily {
      Layout.fillWidth: true
      Layout.leftMargin: Style.marginS
      Layout.rightMargin: Style.marginS
      Layout.bottomMargin: Style.marginS
      visible: LocationService.weatherReady && root.forecastDays > 0
      compact: true
      showTitle: false
      count: root.forecastDays
    }
  }
}
