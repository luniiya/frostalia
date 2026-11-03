import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

// The wallpaper picker (Modules/Panels/WallpaperPicker): it browses the light and dark
// folders from General and shows its pick with the renderer
ColumnLayout {
  id: root
  spacing: Style.marginL
  Layout.fillWidth: true

  readonly property var prefs: Settings.data.wallpaperPicker

  NHeader {
    label: I18n.tr("panels.wallpaper.picker-title")
    description: I18n.tr("panels.wallpaper.picker-desc")
    Layout.fillWidth: true
  }

  NComboBox {
    Layout.fillWidth: true
    label: I18n.tr("panels.wallpaper.picker-sort-label")
    description: I18n.tr("panels.wallpaper.picker-sort-description")
    model: [
      {
        "key": "name",
        "name": I18n.tr("wallpaper-picker.sort.name")
      },
      {
        "key": "date",
        "name": I18n.tr("wallpaper-picker.sort.date")
      },
      {
        "key": "hue",
        "name": I18n.tr("wallpaper-picker.sort.hue")
      }
    ]
    currentKey: root.prefs.sortBy
    defaultValue: Settings.getDefaultValue("wallpaperPicker.sortBy")
    onSelected: key => root.prefs.sortBy = key
  }

  // Only used when the shell doesn't draw the wallpaper
  NTextInput {
    Layout.fillWidth: true
    visible: !Settings.data.wallpaperRenderer.enabled
    label: I18n.tr("panels.wallpaper.picker-command-label")
    description: I18n.tr("panels.wallpaper.picker-command-description")
    text: root.prefs.applyCommand
    defaultValue: Settings.getDefaultValue("wallpaperPicker.applyCommand")
    onEditingFinished: root.prefs.applyCommand = text
  }
}
