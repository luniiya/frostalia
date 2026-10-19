import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

WeatherSettingsForm {
  id: root

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("panels.desktop-widgets.weather-animated-sky-label")
    description: I18n.tr("panels.desktop-widgets.weather-animated-sky-description")
    checked: root.value("animatedSky")
    onToggled: checked => root.set("animatedSky", checked)
    defaultValue: root.widgetMetadata.animatedSky
  }

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("panels.desktop-widgets.weather-show-condition-label")
    description: I18n.tr("panels.desktop-widgets.weather-show-condition-description")
    checked: root.value("showCondition")
    onToggled: checked => root.set("showCondition", checked)
    defaultValue: root.widgetMetadata.showCondition
  }

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("panels.desktop-widgets.weather-show-high-low-label")
    description: I18n.tr("panels.desktop-widgets.weather-show-high-low-description")
    checked: root.value("showHighLow")
    onToggled: checked => root.set("showHighLow", checked)
    defaultValue: root.widgetMetadata.showHighLow
  }

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("panels.desktop-widgets.weather-show-feels-like-label")
    description: I18n.tr("panels.desktop-widgets.weather-show-feels-like-description")
    checked: root.value("showFeelsLike")
    onToggled: checked => root.set("showFeelsLike", checked)
    defaultValue: root.widgetMetadata.showFeelsLike
  }

  NSpinBox {
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

  NDivider {
    Layout.fillWidth: true
  }

  WeatherBackgroundToggles {
    Layout.fillWidth: true
    form: root
  }
}
