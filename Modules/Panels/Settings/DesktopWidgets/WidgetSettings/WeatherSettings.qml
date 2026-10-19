import QtQuick
import QtQuick.Layouts
import "../../../../../Helpers/WeatherData.js" as WeatherData
import "../../../../../Helpers/WeatherWidget.js" as WeatherWidget
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

  readonly property string selectedView: WeatherWidget.view(value("view"))

  NComboBox {
    Layout.fillWidth: true
    label: I18n.tr("panels.desktop-widgets.weather-view-label")
    description: I18n.tr("panels.desktop-widgets.weather-view-description")
    model: WeatherWidget.views.map(key => ({
      "key": key,
      "name": I18n.tr(WeatherWidget.viewLabels[key])
    }))
    currentKey: root.selectedView
    onSelected: key => root.set("view", key)
    defaultValue: root.widgetMetadata.view
  }

  NToggle {
    visible: root.selectedView === "current"
    Layout.fillWidth: true
    label: I18n.tr("panels.desktop-widgets.weather-animated-sky-label")
    description: I18n.tr("panels.desktop-widgets.weather-animated-sky-description")
    checked: root.value("animatedSky")
    onToggled: checked => root.set("animatedSky", checked)
    defaultValue: root.widgetMetadata.animatedSky
  }

  NToggle {
    visible: root.selectedView === "current"
    Layout.fillWidth: true
    label: I18n.tr("panels.desktop-widgets.weather-show-condition-label")
    description: I18n.tr("panels.desktop-widgets.weather-show-condition-description")
    checked: root.value("showCondition")
    onToggled: checked => root.set("showCondition", checked)
    defaultValue: root.widgetMetadata.showCondition
  }

  NToggle {
    visible: root.selectedView === "current"
    Layout.fillWidth: true
    label: I18n.tr("panels.desktop-widgets.weather-show-high-low-label")
    description: I18n.tr("panels.desktop-widgets.weather-show-high-low-description")
    checked: root.value("showHighLow")
    onToggled: checked => root.set("showHighLow", checked)
    defaultValue: root.widgetMetadata.showHighLow
  }

  NToggle {
    visible: root.selectedView === "current"
    Layout.fillWidth: true
    label: I18n.tr("panels.desktop-widgets.weather-show-feels-like-label")
    description: I18n.tr("panels.desktop-widgets.weather-show-feels-like-description")
    checked: root.value("showFeelsLike")
    onToggled: checked => root.set("showFeelsLike", checked)
    defaultValue: root.widgetMetadata.showFeelsLike
  }

  NSpinBox {
    visible: root.selectedView === "current"
    Layout.fillWidth: true
    label: I18n.tr("panels.desktop-widgets.weather-forecast-days-label")
    description: I18n.tr("panels.desktop-widgets.weather-forecast-days-description")
    from: 0
    to: 7
    value: root.value("forecastDays")
    onValueChanged: if (value !== root.value("forecastDays"))
                      root.set("forecastDays", value)
    defaultValue: root.widgetMetadata.forecastDays
  }

  NSpinBox {
    visible: root.selectedView === "hourly"
    Layout.fillWidth: true
    label: I18n.tr("panels.desktop-widgets.weather-hours-label")
    description: I18n.tr("panels.desktop-widgets.weather-hours-description")
    from: 4
    to: 48
    value: root.value("hours")
    onValueChanged: if (value !== root.value("hours"))
                      root.set("hours", value)
    defaultValue: root.widgetMetadata.hours
  }

  NSpinBox {
    visible: root.selectedView === "daily"
    Layout.fillWidth: true
    label: I18n.tr("panels.desktop-widgets.weather-days-label")
    description: I18n.tr("panels.desktop-widgets.weather-days-description")
    from: 3
    to: 7
    value: root.value("days")
    onValueChanged: if (value !== root.value("days"))
                      root.set("days", value)
    defaultValue: root.widgetMetadata.days
  }

  NToggle {
    visible: root.selectedView === "daily"
    Layout.fillWidth: true
    label: I18n.tr("panels.desktop-widgets.weather-compact-label")
    description: I18n.tr("panels.desktop-widgets.weather-compact-description")
    checked: root.value("compact")
    onToggled: checked => root.set("compact", checked)
    defaultValue: root.widgetMetadata.compact
  }

  NComboBox {
    visible: root.selectedView === "detail"
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

  NToggle {
    Layout.fillWidth: true
    visible: root.selectedView === "hourly" || root.selectedView === "daily"
    label: I18n.tr("panels.desktop-widgets.weather-show-precipitation-label")
    description: I18n.tr("panels.desktop-widgets.weather-show-precipitation-description")
    checked: root.value("showPrecipitation")
    onToggled: checked => root.set("showPrecipitation", checked)
    defaultValue: root.widgetMetadata.showPrecipitation
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
