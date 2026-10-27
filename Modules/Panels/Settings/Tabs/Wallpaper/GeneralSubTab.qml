import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../../../../../Helpers/WallpaperRenderer.js" as WallpaperRenderer
import qs.Commons
import qs.Services.UI
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginL
  Layout.fillWidth: true

  readonly property var prefs: Settings.data.wallpaperRenderer
  // Which folder the picker fills in: "light" or "dark"
  property string picking: "light"

  function openPicker(mode) {
    picking = mode;
    const folder = WallpaperRenderer.folderFor(mode, prefs, Quickshell.env("HOME"));
    folderPicker.initialPath = folder || Quickshell.env("HOME");
    folderPicker.currentPath = folderPicker.initialPath;
    folderPicker.openFilePicker();
  }

  NToggle {
    label: I18n.tr("panels.wallpaper.renderer-enabled-label")
    description: I18n.tr("panels.wallpaper.renderer-enabled-description")
    checked: root.prefs.enabled
    defaultValue: Settings.getDefaultValue("wallpaperRenderer.enabled")
    onToggled: checked => root.prefs.enabled = checked
  }

  NTextInputButton {
    enabled: root.prefs.enabled
    label: I18n.tr("panels.wallpaper.light-folder-label")
    description: I18n.tr("panels.wallpaper.light-folder-description")
    text: root.prefs.lightFolder
    placeholderText: "~/Wall/Light" // don't translate path
    buttonIcon: "folder-open"
    buttonTooltip: I18n.tr("panels.wallpaper.select-folder")
    onInputEditingFinished: root.prefs.lightFolder = text
    onButtonClicked: root.openPicker("light")
  }

  NTextInputButton {
    enabled: root.prefs.enabled
    label: I18n.tr("panels.wallpaper.dark-folder-label")
    description: I18n.tr("panels.wallpaper.dark-folder-description")
    text: root.prefs.darkFolder
    placeholderText: "~/Wall/Dark" // don't translate path
    buttonIcon: "folder-open"
    buttonTooltip: I18n.tr("panels.wallpaper.select-folder")
    onInputEditingFinished: root.prefs.darkFolder = text
    onButtonClicked: root.openPicker("dark")
  }

  NFilePicker {
    id: folderPicker
    title: I18n.tr("panels.wallpaper.select-folder")
    selectionMode: "folders"
    onAccepted: paths => {
      if (paths.length === 0)
        return;
      if (root.picking === "dark")
        root.prefs.darkFolder = paths[0];
      else
        root.prefs.lightFolder = paths[0];
    }
  }

  NSpinBox {
    Layout.fillWidth: true
    enabled: root.prefs.enabled
    label: I18n.tr("panels.wallpaper.random-minutes-label")
    description: I18n.tr("panels.wallpaper.random-minutes-description")
    from: 0
    to: 1440
    stepSize: 5
    suffix: " min"
    value: root.prefs.randomMinutes
    defaultValue: Settings.getDefaultValue("wallpaperRenderer.randomMinutes")
    onValueChanged: root.prefs.randomMinutes = value
  }

  NDivider {
    Layout.fillWidth: true
  }

  NToggle {
    enabled: root.prefs.enabled
    label: I18n.tr("panels.wallpaper.precache-label")
    description: I18n.tr("panels.wallpaper.precache-description")
    checked: root.prefs.precache
    defaultValue: Settings.getDefaultValue("wallpaperRenderer.precache")
    onToggled: checked => root.prefs.precache = checked
  }

  NButton {
    icon: "trash"
    text: I18n.tr("panels.wallpaper.settings-clear-cache-button")
    outlined: true
    Layout.fillWidth: true
    onClicked: {
      ImageCacheService.clearScreenWallpapers();
      ToastService.showNotice(I18n.tr("panels.wallpaper.title"), I18n.tr("panels.wallpaper.settings-clear-cache-toast"));
    }
  }
}
