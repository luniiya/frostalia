import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

WeatherSettingsForm {
  id: root

  NSpinBox {
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

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("panels.desktop-widgets.weather-show-precipitation-label")
    description: I18n.tr("panels.desktop-widgets.weather-show-precipitation-description")
    checked: root.value("showPrecipitation")
    onToggled: checked => root.set("showPrecipitation", checked)
    defaultValue: root.widgetMetadata.showPrecipitation
  }

  NDivider {
    Layout.fillWidth: true
  }

  WeatherBackgroundToggles {
    Layout.fillWidth: true
    form: root
  }
}
