import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

WeatherSettingsForm {
  id: root

  NSpinBox {
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
    Layout.fillWidth: true
    label: I18n.tr("panels.desktop-widgets.weather-compact-label")
    description: I18n.tr("panels.desktop-widgets.weather-compact-description")
    checked: root.value("compact")
    onToggled: checked => root.set("compact", checked)
    defaultValue: root.widgetMetadata.compact
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
