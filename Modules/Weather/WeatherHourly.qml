import QtQuick
import QtQuick.Layouts
import "../../Helpers/WeatherData.js" as WeatherData
import "../../Helpers/WeatherWidget.js" as WeatherWidget
import qs.Commons
import qs.Services.Location
import qs.Widgets

// Hourly forecast: a temperature curve with an icon, time and rain chance per hour.
// Scrolls sideways when the hours don't fit.
Item {
  id: root

  property int count: Settings.data.location.weatherHourlyCount
  property bool showPrecipitation: true
  property real scaleFactor: 1.0

  readonly property var hours: LocationService.hourlyForecast.slice(0, Math.max(1, count))
  readonly property bool fahrenheit: Settings.data.location.useFahrenheit
  readonly property real columnWidth: Math.round(52 * Style.uiScaleRatio * scaleFactor)
  readonly property real curveHeight: Math.round(56 * Style.uiScaleRatio * scaleFactor)
  readonly property real labelHeight: Math.round(Style.fontSizeS * 1.6 * Style.uiScaleRatio * scaleFactor)
  readonly property var temperatures: hours.map(hour => WeatherData.temperature(hour.temperature, fahrenheit))
  readonly property var points: WeatherData.chartPoints(temperatures, flick.contentWidth, labelHeight + Style.marginXS, curveHeight - Style.marginXS)
  readonly property bool material: Style.uiStyleTokens.weather !== undefined

  function hourLabel(hour, index) {
    if (index === 0)
      return I18n.tr("weather.now");
    const date = new Date(hour.time);
    return I18n.locale.toString(date, Settings.data.location.use12hourFormat ? "h AP" : "HH:mm");
  }

  implicitWidth: Math.round(360 * Style.uiScaleRatio * scaleFactor)
  implicitHeight: column.implicitHeight

  ColumnLayout {
    id: column
    anchors.fill: parent
    spacing: Style.marginS

    NText {
      text: I18n.tr("weather.hourly")
      pointSize: Style.fontSizeM * root.scaleFactor
      font.weight: Style.fontWeightMedium
      color: ShellColors.mOnSurface
    }

    Flickable {
      id: flick
      Layout.fillWidth: true
      Layout.preferredHeight: contentHeight
      contentWidth: Math.max(width, root.hours.length * root.columnWidth)
      contentHeight: columns.implicitHeight
      flickableDirection: Flickable.HorizontalFlick
      boundsBehavior: Flickable.StopAtBounds
      clip: true

      // Mouse wheels scroll sideways
      WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
          const delta = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x;
          flick.contentX = Math.max(0, Math.min(flick.contentWidth - flick.width, flick.contentX - delta));
        }
      }

      Column {
        id: columns
        width: flick.contentWidth

        Item {
          id: curve
          width: parent.width
          height: root.curveHeight

          Canvas {
            id: canvas
            anchors.fill: parent
            onPaint: {
              const ctx = getContext("2d");
              ctx.reset();
              const points = root.points;
              if (points.length < 2)
                return;
              // Smooth curve through the midpoints between hours
              ctx.beginPath();
              ctx.moveTo(0, points[0].y);
              ctx.lineTo(points[0].x, points[0].y);
              for (let i = 1; i < points.length; i++) {
                const midX = (points[i - 1].x + points[i].x) / 2;
                ctx.bezierCurveTo(midX, points[i - 1].y, midX, points[i].y, points[i].x, points[i].y);
              }
              ctx.lineTo(width, points[points.length - 1].y);
              ctx.lineWidth = (root.material ? 3 : 2) * Style.uiScaleRatio;
              ctx.strokeStyle = ShellColors.mPrimary;
              ctx.lineCap = "round";
              ctx.stroke();
              ctx.lineTo(width, height);
              ctx.lineTo(0, height);
              ctx.closePath();
              const fill = ctx.createLinearGradient(0, 0, 0, height);
              fill.addColorStop(0, Qt.alpha(ShellColors.mPrimary, 0.22));
              fill.addColorStop(1, Qt.alpha(ShellColors.mPrimary, 0));
              ctx.fillStyle = fill;
              ctx.fill();
            }

            Connections {
              target: root
              function onPointsChanged() {
                canvas.requestPaint();
              }
            }
            Connections {
              target: ShellColors
              function onMPrimaryChanged() {
                canvas.requestPaint();
              }
            }
          }

          Repeater {
            model: root.points.length

            Item {
              required property int index
              readonly property var point: root.points[index]

              Rectangle {
                x: parent.point.x - width / 2
                y: parent.point.y - height / 2
                width: Math.round(6 * Style.uiScaleRatio * root.scaleFactor)
                height: width
                radius: width / 2
                color: ShellColors.mPrimary
              }

              NText {
                x: parent.point.x - width / 2
                y: parent.point.y - height - Style.marginXS
                text: root.temperatures[parent.index] === null ? "--" : root.temperatures[parent.index] + "°"
                pointSize: Style.fontSizeS * root.scaleFactor
                font.weight: Style.fontWeightMedium
                color: ShellColors.mOnSurface
              }
            }
          }
        }

        Row {
          Repeater {
            model: root.hours

            ColumnLayout {
              required property var modelData
              required property int index
              width: WeatherWidget.hourlyColumnWidth(flick.contentWidth, root.hours.length)
              spacing: Style.marginXXS

              WeatherIcon {
                Layout.alignment: Qt.AlignHCenter
                code: modelData.code
                isDay: modelData.isDay
                pointSize: Style.fontSizeL * root.scaleFactor
                color: ShellColors.mPrimary
              }

              NText {
                Layout.alignment: Qt.AlignHCenter
                readonly property var rain: WeatherWidget.precipitationLabel(modelData.precipitationProbability)
                visible: root.showPrecipitation
                text: rain.text
                pointSize: Style.fontSizeXS * root.scaleFactor
                color: rain.dim ? ShellColors.mOnSurfaceVariant : ShellColors.mPrimary
                opacity: rain.dim ? 0.5 : 1
              }

              NText {
                Layout.alignment: Qt.AlignHCenter
                text: root.hourLabel(modelData, index)
                pointSize: Style.fontSizeXS * root.scaleFactor
                color: index === 0 ? ShellColors.mOnSurface : ShellColors.mOnSurfaceVariant
                font.weight: index === 0 ? Style.fontWeightBold : Style.fontWeightRegular
              }
            }
          }
        }
      }
    }
  }
}
