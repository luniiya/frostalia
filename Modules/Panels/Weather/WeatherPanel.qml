import QtQuick
import qs.Commons
import qs.Modules.Cards
import qs.Modules.MainScreen

SmartPanel {
  id: root

  panelContent: Item {
    anchors.fill: parent
    readonly property real contentPreferredWidth: Math.round(420 * Style.uiScaleRatio)
    readonly property real contentPreferredHeight: weatherCard.implicitHeight + Style.margin2L

    WeatherCard {
      id: weatherCard
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: Style.marginL
    }
  }
}
