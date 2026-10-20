import QtQuick
import QtQuick.Layouts
import "../../Helpers/WeatherData.js" as WeatherData
import "../../Helpers/WeatherWidget.js" as WeatherWidget
import qs.Commons
import qs.Services.Location
import qs.Widgets

// Daily forecast: one row per day with rain chance and a min/max range bar
// placed on the scale of the whole week. `compact` lays the days out side by side.
Item {
  id: root

  property int count: Settings.data.location.weatherDailyCount
  property bool showPrecipitation: true
  property bool showTitle: true
  property bool compact: false
  property real scaleFactor: 1.0

  readonly property var days: LocationService.dailyForecast.slice(0, Math.max(1, count))
  readonly property bool fahrenheit: Settings.data.location.useFahrenheit
  readonly property var range: WeatherData.bounds(days.map(day => day.min).concat(days.map(day => day.max)))
  readonly property real rowHeight: Math.round(Style.baseWidgetSize * 1.05 * Style.uiScaleRatio * scaleFactor)

  function dayLabel(day, index) {
    if (index === 0)
      return I18n.tr("weather.today");
    return I18n.locale.toString(new Date(day.date.replace(/-/g, "/")), "ddd");
  }

  implicitWidth: Math.round(320 * Style.uiScaleRatio * scaleFactor)
  implicitHeight: column.implicitHeight

  ColumnLayout {
    id: column
    anchors.fill: parent
    spacing: 0

    NText {
      Layout.bottomMargin: Style.marginS
      visible: root.showTitle
      text: I18n.tr("weather.daily", {
                      "count": root.days.length
                    })
      pointSize: Style.fontSizeM * root.scaleFactor
      font.weight: Style.fontWeightMedium
      color: ShellColors.mOnSurface
    }

    RowLayout {
      Layout.fillWidth: true
      visible: root.compact
      spacing: Style.marginS

      Repeater {
        model: root.compact ? root.days : []

        ColumnLayout {
          required property var modelData
          required property int index
          Layout.fillWidth: true
          Layout.preferredWidth: 1
          // Nested layouts otherwise cap their width at the centered labels.
          Layout.maximumWidth: Infinity
          spacing: Style.marginXS

          NText {
            Layout.alignment: Qt.AlignHCenter
            text: root.dayLabel(modelData, index)
            pointSize: Style.fontSizeS * root.scaleFactor
            font.weight: index === 0 ? Style.fontWeightBold : Style.fontWeightRegular
            color: ShellColors.mOnSurface
          }

          WeatherIcon {
            Layout.alignment: Qt.AlignHCenter
            code: modelData.code
            pointSize: Style.fontSizeXL * root.scaleFactor
            color: ShellColors.mPrimary
          }

          NText {
            Layout.alignment: Qt.AlignHCenter
            readonly property var rain: WeatherWidget.precipitationLabel(modelData.precipitationProbability)
            visible: root.showPrecipitation
            text: rain.text
            pointSize: Style.fontSizeXXS * root.scaleFactor
            color: rain.dim ? ShellColors.mOnSurfaceVariant : ShellColors.mPrimary
            opacity: rain.dim ? 0.5 : 1
          }

          NText {
            Layout.alignment: Qt.AlignHCenter
            text: WeatherData.temperatureText(modelData.max, root.fahrenheit, false) + " " + WeatherData.temperatureText(modelData.min, root.fahrenheit, false)
            pointSize: Style.fontSizeXS * root.scaleFactor
            color: ShellColors.mOnSurfaceVariant
          }
        }
      }
    }

    Repeater {
      model: root.compact ? [] : root.days

      RowLayout {
        required property var modelData
        required property int index
        readonly property var bar: WeatherData.rangeBar(modelData.min, modelData.max, root.range.min, root.range.max)

        Layout.fillWidth: true
        Layout.preferredHeight: root.rowHeight
        spacing: Math.round(Style.marginM * root.scaleFactor)

        NText {
          Layout.preferredWidth: Math.round(52 * Style.uiScaleRatio * root.scaleFactor)
          text: root.dayLabel(modelData, index)
          pointSize: Style.fontSizeM * root.scaleFactor
          font.weight: index === 0 ? Style.fontWeightBold : Style.fontWeightRegular
          color: ShellColors.mOnSurface
        }

        WeatherIcon {
          code: modelData.code
          pointSize: Style.fontSizeL * root.scaleFactor
          color: ShellColors.mPrimary
        }

        NText {
          Layout.preferredWidth: Math.round(34 * Style.uiScaleRatio * root.scaleFactor)
          readonly property var rain: WeatherWidget.precipitationLabel(modelData.precipitationProbability)
          visible: root.showPrecipitation
          text: rain.text
          pointSize: Style.fontSizeXS * root.scaleFactor
          color: rain.dim ? ShellColors.mOnSurfaceVariant : ShellColors.mPrimary
          opacity: rain.dim ? 0.5 : 1
        }

        NText {
          Layout.preferredWidth: Math.round(30 * Style.uiScaleRatio * root.scaleFactor)
          horizontalAlignment: Text.AlignRight
          text: WeatherData.temperatureText(modelData.min, root.fahrenheit, false)
          pointSize: Style.fontSizeM * root.scaleFactor
          color: ShellColors.mOnSurfaceVariant
        }

        // Week-wide track with the day's range highlighted
        Rectangle {
          id: track
          Layout.fillWidth: true
          Layout.minimumWidth: Math.round(48 * Style.uiScaleRatio * root.scaleFactor)
          Layout.preferredHeight: Math.round(6 * Style.uiScaleRatio * root.scaleFactor)
          radius: height / 2
          color: Qt.alpha(ShellColors.mOnSurface, 0.12)

          Rectangle {
            x: track.width * parent.parent.bar.start
            width: Math.max(track.height, track.width * (parent.parent.bar.end - parent.parent.bar.start))
            height: parent.height
            radius: parent.radius
            gradient: Gradient {
              orientation: Gradient.Horizontal
              GradientStop {
                position: 0
                color: ShellColors.mSecondary
              }
              GradientStop {
                position: 1
                color: ShellColors.mPrimary
              }
            }
          }
        }

        NText {
          Layout.preferredWidth: Math.round(30 * Style.uiScaleRatio * root.scaleFactor)
          text: WeatherData.temperatureText(modelData.max, root.fahrenheit, false)
          pointSize: Style.fontSizeM * root.scaleFactor
          font.weight: Style.fontWeightMedium
          color: ShellColors.mOnSurface
        }
      }
    }
  }
}
