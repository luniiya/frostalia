import QtQuick
import qs.Commons
import qs.Services.Location
import qs.Widgets
import "../../Helpers/WeatherData.js" as WeatherData

// Condition icon for a WMO code; Talia stands in for it on her day.
Item {
  id: root

  property int code: 0
  property bool isDay: true
  property real pointSize: Style.fontSizeXL
  property color color: ShellColors.mPrimary

  readonly property real side: Math.round(pointSize * 1.6 * Style.uiScaleRatio)

  implicitWidth: side
  implicitHeight: side

  NIcon {
    visible: !LocationService.taliaWeatherMascotActive
    anchors.centerIn: parent
    icon: WeatherData.symbol(root.code, root.isDay)
    pointSize: root.pointSize
    color: root.color
  }

  Loader {
    active: LocationService.taliaWeatherMascotActive
    anchors.fill: parent
    asynchronous: true
    sourceComponent: Image {
      fillMode: Image.PreserveAspectFit
      smooth: true
      mipmap: true
      asynchronous: true
      source: Qt.resolvedUrl(LocationService.taliaWeatherImageFromCode(root.code))
    }
  }
}
