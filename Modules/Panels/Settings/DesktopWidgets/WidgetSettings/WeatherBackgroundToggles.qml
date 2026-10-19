import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

// Background and corner toggles shared by the weather widget settings.
ColumnLayout {
  id: root
  spacing: Style.marginM

  required property var form

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("panels.desktop-widgets.clock-show-background-label")
    description: I18n.tr("panels.desktop-widgets.weather-show-background-description")
    checked: root.form.value("showBackground")
    onToggled: checked => root.form.set("showBackground", checked)
    defaultValue: root.form.widgetMetadata.showBackground
  }

  NToggle {
    Layout.fillWidth: true
    visible: root.form.value("showBackground")
    label: I18n.tr("panels.desktop-widgets.clock-rounded-corners-label")
    description: I18n.tr("panels.desktop-widgets.clock-rounded-corners-description")
    checked: root.form.value("roundedCorners")
    onToggled: checked => root.form.set("roundedCorners", checked)
    defaultValue: root.form.widgetMetadata.roundedCorners
  }
}
