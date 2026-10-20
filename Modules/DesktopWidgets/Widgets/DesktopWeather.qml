import QtQuick
import QtQuick.Layouts
import "../../../Helpers/WeatherWidget.js" as WeatherWidget
import qs.Commons
import qs.Modules.DesktopWidgets
import qs.Modules.Weather
import qs.Services.Location

// Current conditions and forecasts in one desktop widget.
DraggableDesktopWidget {
  id: root
  horizontalResizable: true
  verticalResizable: false

  readonly property string view: WeatherWidget.view(widgetSetting("view"))
  readonly property int forecastDays: widgetSetting("forecastDays") ?? 0
  readonly property real padding: Math.round(Style.marginM * widgetScale)
  readonly property var baseSize: WeatherWidget.desktopSize(view, widgetSetting("compact") ?? false)

  implicitWidth: view === "hourly" && viewLoader.item ? viewLoader.item.implicitWidth : Math.round(baseSize.width * widgetScale)
  implicitHeight: baseSize.height > 0 ? Math.round(baseSize.height * widgetScale) : (viewLoader.item ? viewLoader.item.implicitHeight : 0)

  Loader {
    id: viewLoader
    anchors.fill: parent
    sourceComponent: {
      switch (root.view) {
      case "hourly":
        return hourlyView;
      case "daily":
        return dailyView;
      default:
        return currentView;
      }
    }
  }

  Component {
    id: currentView

    ColumnLayout {
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

  Component {
    id: hourlyView

    Item {
      implicitWidth: WeatherWidget.hourlyWidgetWidth(hourly.hours.length, hourly.columnWidth, root.padding, root.baseSize.width * root.widgetScale)
      implicitHeight: hourly.implicitHeight + root.padding * 2

      WeatherHourly {
        id: hourly
        anchors.fill: parent
        anchors.margins: root.padding
        scaleFactor: root.widgetScale
        count: root.widgetSetting("hours") ?? 12
        showPrecipitation: root.widgetSetting("showPrecipitation") ?? true
      }
    }
  }

  Component {
    id: dailyView

    Item {
      implicitHeight: daily.implicitHeight + root.padding * 2

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
  }
}
