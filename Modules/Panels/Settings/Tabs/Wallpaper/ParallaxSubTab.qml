import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginL
  Layout.fillWidth: true

  readonly property var prefs: Settings.data.wallpaperRenderer
  readonly property bool active: prefs.enabled && prefs.parallax

  NToggle {
    enabled: root.prefs.enabled
    label: I18n.tr("panels.wallpaper.parallax-label")
    description: I18n.tr("panels.wallpaper.parallax-description")
    checked: root.prefs.parallax
    defaultValue: Settings.getDefaultValue("wallpaperRenderer.parallax")
    onToggled: checked => root.prefs.parallax = checked
  }

  NValueSlider {
    Layout.fillWidth: true
    enabled: root.active
    label: I18n.tr("panels.wallpaper.parallax-amount-label")
    description: I18n.tr("panels.wallpaper.parallax-amount-description")
    from: 2
    to: 30
    stepSize: 1
    showReset: true
    value: root.prefs.parallaxAmount
    defaultValue: Settings.getDefaultValue("wallpaperRenderer.parallaxAmount")
    onMoved: value => root.prefs.parallaxAmount = Math.round(value)
    text: root.prefs.parallaxAmount + "%"
  }

  NSpinBox {
    Layout.fillWidth: true
    enabled: root.active
    label: I18n.tr("panels.wallpaper.parallax-workspaces-label")
    description: I18n.tr("panels.wallpaper.parallax-workspaces-description")
    from: 2
    to: 20
    stepSize: 1
    value: root.prefs.parallaxWorkspaces
    defaultValue: Settings.getDefaultValue("wallpaperRenderer.parallaxWorkspaces")
    onValueChanged: root.prefs.parallaxWorkspaces = value
  }

  NValueSlider {
    Layout.fillWidth: true
    enabled: root.active
    label: I18n.tr("panels.wallpaper.parallax-duration-label")
    description: I18n.tr("panels.wallpaper.parallax-duration-description")
    from: 0
    to: 1500
    stepSize: 50
    showReset: true
    value: root.prefs.parallaxDuration
    defaultValue: Settings.getDefaultValue("wallpaperRenderer.parallaxDuration")
    onMoved: value => root.prefs.parallaxDuration = Math.round(value)
    text: root.prefs.parallaxDuration + " ms"
  }
}
