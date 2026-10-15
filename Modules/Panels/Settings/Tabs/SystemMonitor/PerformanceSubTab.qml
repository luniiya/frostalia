import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginL
  Layout.fillWidth: true

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("panels.system.frostalia-performance-disable-desktop-widgets-label")
    description: I18n.tr("panels.system.frostalia-performance-disable-desktop-widgets-description")
    checked: !Settings.data.frostaliaPerformance.disableDesktopWidgets
    defaultValue: !Settings.getDefaultValue("frostaliaPerformance.disableDesktopWidgets")
    onToggled: checked => Settings.data.frostaliaPerformance.disableDesktopWidgets = !checked
  }
}
