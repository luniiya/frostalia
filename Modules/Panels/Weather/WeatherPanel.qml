import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Modules.MainScreen
import qs.Modules.Weather
import qs.Widgets

SmartPanel {
  id: root

  preferredWidth: Math.round(460 * Style.uiScaleRatio)
  preferredHeight: Math.round(860 * Style.uiScaleRatio)

  panelContent: Item {
    anchors.fill: parent
    readonly property real contentPreferredWidth: root.preferredWidth
    readonly property real contentPreferredHeight: Math.min(root.preferredHeight, view.implicitHeight + Style.margin2L)

    NScrollView {
      id: scrollView
      anchors.fill: parent
      anchors.margins: Style.marginL
      horizontalPolicy: ScrollBar.AlwaysOff
      reserveScrollbarSpace: false
      showGradientMasks: false

      WeatherView {
        id: view
        width: scrollView.availableWidth
      }
    }
  }
}
