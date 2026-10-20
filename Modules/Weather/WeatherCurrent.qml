import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import "../../Helpers/WeatherData.js" as WeatherData
import "../../Helpers/WeatherWidget.js" as WeatherWidget
import qs.Commons
import qs.Services.Location
import qs.Services.Power
import qs.Widgets

// Current conditions: big temperature and condition badge, optionally over the animated sky.
Item {
  id: root

  property real scaleFactor: 1.0
  property real radius: 0
  property bool showSky: Settings.data.location.weatherShowEffects
  property bool showLocation: !Settings.data.location.hideWeatherCityName
  property bool showCondition: true
  property bool showHighLow: true
  property bool showFeelsLike: true

  readonly property var now: LocationService.currentWeather
  readonly property var today: LocationService.dailyForecast.length > 0 ? LocationService.dailyForecast[0] : null
  readonly property bool ready: LocationService.weatherReady && now !== null
  readonly property bool fahrenheit: Settings.data.location.useFahrenheit
  readonly property bool skyVisible: showSky && ready
  readonly property color textColor: skyVisible ? sky.textColor : ShellColors.mOnSurface
  readonly property color secondaryTextColor: skyVisible ? Qt.alpha(sky.textColor, 0.8) : ShellColors.mOnSurfaceVariant
  property real padding: Math.round(Style.marginL * scaleFactor)
  property real badgeSize: Math.round(88 * Style.uiScaleRatio * scaleFactor)
  property real temperatureSize: Style.fontSizeXXXL * 2.2 * scaleFactor

  implicitWidth: Math.round(320 * Style.uiScaleRatio * scaleFactor)
  implicitHeight: Math.max(content.implicitHeight, badgeSize) + padding * 2

  Item {
    id: skyLayer
    anchors.fill: parent
    visible: root.skyVisible
    layer.enabled: root.radius > 0
    layer.effect: MultiEffect {
      maskEnabled: true
      maskSource: skyMask
      maskThresholdMin: 0.5
      maskSpreadAtMin: 1.0
    }

    WeatherBackground {
      id: sky
      anchors.fill: parent
      weatherCode: root.ready ? root.now.code : 0
      night: root.ready && !root.now.isDay
      windSpeedMs: root.ready && root.now.windSpeed !== null ? root.now.windSpeed / 3.6 : 0
      windGustsMs: root.ready && root.now.windGusts !== null ? root.now.windGusts / 3.6 : 0
      animate: root.skyVisible && root.visible && !PowerProfileService.frostaliaPerformanceMode
    }
  }

  Item {
    id: skyMask
    anchors.fill: parent
    layer.enabled: true
    visible: false

    Rectangle {
      anchors.fill: parent
      radius: root.radius
    }
  }

  RowLayout {
    id: content
    visible: root.ready
    anchors.fill: parent
    anchors.margins: root.padding
    spacing: Math.round(Style.marginM * root.scaleFactor)

    ColumnLayout {
      Layout.fillWidth: true
      Layout.alignment: Qt.AlignVCenter
      spacing: 0

      NText {
        Layout.fillWidth: true
        visible: root.showLocation && Settings.data.location.name !== ""
        text: Settings.data.location.name.split(",")[0]
        pointSize: Style.fontSizeM * root.scaleFactor
        font.weight: Style.fontWeightMedium
        color: root.secondaryTextColor
        elide: Text.ElideRight
      }

      NText {
        text: root.ready ? WeatherData.temperatureText(root.now.temperature, root.fahrenheit, false) : ""
        pointSize: root.temperatureSize
        font.weight: Style.fontWeightRegular
        color: root.textColor
      }

      NText {
        Layout.fillWidth: true
        visible: root.showCondition
        text: root.ready ? I18n.tr(WeatherWidget.conditionKey(root.now.code)) : ""
        pointSize: Style.fontSizeL * root.scaleFactor
        font.weight: Style.fontWeightMedium
        color: root.textColor
        elide: Text.ElideRight
      }

      NText {
        Layout.fillWidth: true
        visible: text !== ""
        text: {
          const parts = [];
          if (root.showHighLow && root.today)
            parts.push(I18n.tr("weather.high-low", {
                                 "high": WeatherData.temperatureText(root.today.max, root.fahrenheit, false),
                                 "low": WeatherData.temperatureText(root.today.min, root.fahrenheit, false)
                               }));
          if (root.showFeelsLike && root.ready && root.now.feelsLike !== null)
            parts.push(I18n.tr("weather.feels-like", {
                                 "value": WeatherData.temperatureText(root.now.feelsLike, root.fahrenheit, false)
                               }));
          return parts.join("  ·  ");
        }
        pointSize: Style.fontSizeS * root.scaleFactor
        color: root.secondaryTextColor
        elide: Text.ElideRight
      }
    }

    Item {
      Layout.preferredWidth: root.badgeSize
      Layout.preferredHeight: root.badgeSize
      Layout.alignment: Qt.AlignVCenter

      WeatherShape {
        anchors.fill: parent
        fillColor: ShellColors.mPrimary
      }

      WeatherIcon {
        anchors.centerIn: parent
        code: root.ready ? root.now.code : 0
        isDay: root.ready ? root.now.isDay : true
        pointSize: Style.fontSizeXXXL * 1.3 * root.scaleFactor
        color: ShellColors.mOnPrimary
      }
    }
  }

  ColumnLayout {
    visible: !root.ready
    anchors.centerIn: parent
    spacing: Style.marginS

    NBusyIndicator {
      Layout.alignment: Qt.AlignHCenter
      visible: LocationService.locationConfigured && Settings.data.location.weatherEnabled
    }

    NText {
      Layout.alignment: Qt.AlignHCenter
      visible: !LocationService.locationConfigured
      text: I18n.tr("common.weather-no-location")
      pointSize: Style.fontSizeS
      color: ShellColors.mOnSurfaceVariant
    }
  }
}
