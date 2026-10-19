import QtQuick
import QtQuick.Layouts
import "../../../../../Helpers/WeatherData.js" as WeatherData
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginM

  property var widgetData: null
  property var widgetMetadata: null
  property var values: Object.assign({}, widgetMetadata || {}, widgetData || {})

  signal settingsChanged(var settings)

  function value(key) {
    return values[key];
  }

  function set(key, newValue) {
    const next = Object.assign({}, values);
    next[key] = newValue;
    values = next;
    settingsChanged(Object.assign({}, widgetData || {}, next));
  }

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

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("panels.desktop-widgets.clock-show-background-label")
    description: I18n.tr("panels.desktop-widgets.weather-show-background-description")
    checked: root.value("showBackground")
    onToggled: checked => root.set("showBackground", checked)
    defaultValue: root.widgetMetadata.showBackground
  }

  NToggle {
    Layout.fillWidth: true
    visible: root.value("showBackground")
    label: I18n.tr("panels.desktop-widgets.clock-rounded-corners-label")
    description: I18n.tr("panels.desktop-widgets.clock-rounded-corners-description")
    checked: root.value("roundedCorners")
    onToggled: checked => root.set("roundedCorners", checked)
    defaultValue: root.widgetMetadata.roundedCorners
  }
}
