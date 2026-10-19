import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "../../../../../Helpers/WeatherData.js" as WeatherData

WeatherSettingsForm {
  id: root

  NComboBox {
    Layout.fillWidth: true
    label: I18n.tr("panels.desktop-widgets.weather-detail-label")
    description: I18n.tr("panels.desktop-widgets.weather-detail-description")
    minimumWidth: 200 * Style.uiScaleRatio
    model: WeatherData.detailKinds.map(kind => ({
                                                  "key": kind,
                                                  "name": I18n.tr("weather.details." + kind)
                                                }))
    currentKey: root.value("detail")
    onSelected: key => root.set("detail", key)
    defaultValue: root.widgetMetadata.detail
  }

  NDivider {
    Layout.fillWidth: true
  }

  WeatherBackgroundToggles {
    Layout.fillWidth: true
    form: root
  }
}
