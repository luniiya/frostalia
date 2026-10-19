import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services.Location
import "../../Helpers/WeatherData.js" as WeatherData

// The full weather page: current conditions, hourly, daily and detail tiles.
// Each section can be turned off in Settings > Region > Location.
ColumnLayout {
  id: root

  property int detailColumns: 2

  readonly property var details: WeatherData.enabledDetails(Settings.data.location.weatherDetails)

  spacing: Style.marginM

  WeatherSurface {
    id: heroSurface
    Layout.fillWidth: true
    Layout.preferredHeight: hero.implicitHeight

    WeatherCurrent {
      id: hero
      anchors.fill: parent
      radius: heroSurface.radius
    }
  }

  WeatherSurface {
    Layout.fillWidth: true
    Layout.preferredHeight: hourly.implicitHeight + Style.margin2L
    visible: LocationService.weatherReady && Settings.data.location.weatherShowHourly && LocationService.hourlyForecast.length > 0

    WeatherHourly {
      id: hourly
      anchors.fill: parent
      anchors.margins: Style.marginL
    }
  }

  WeatherSurface {
    Layout.fillWidth: true
    Layout.preferredHeight: daily.implicitHeight + Style.margin2L
    visible: LocationService.weatherReady && Settings.data.location.weatherShowDaily

    WeatherDaily {
      id: daily
      anchors.fill: parent
      anchors.margins: Style.marginL
    }
  }

  GridLayout {
    Layout.fillWidth: true
    visible: LocationService.weatherReady && Settings.data.location.weatherShowDetails && root.details.length > 0
    columns: root.detailColumns
    rowSpacing: Style.marginM
    columnSpacing: Style.marginM

    Repeater {
      model: root.details

      WeatherSurface {
        required property string modelData
        tile: true
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        Layout.preferredHeight: detailTile.implicitHeight + Style.margin2L

        WeatherDetailTile {
          id: detailTile
          anchors.fill: parent
          anchors.margins: Style.marginL
          kind: modelData
        }
      }
    }
  }
}
