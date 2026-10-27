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

  NComboBox {
    enabled: root.prefs.enabled
    label: I18n.tr("panels.wallpaper.transition-label")
    description: I18n.tr("panels.wallpaper.transition-description")
    model: [
      {
        "key": "random",
        "name": I18n.tr("common.random")
      },
      {
        "key": "ring",
        "name": I18n.tr("wallpaper.transitions.ring")
      },
      {
        "key": "star",
        "name": I18n.tr("wallpaper.transitions.star")
      },
      {
        "key": "iris",
        "name": I18n.tr("wallpaper.transitions.iris")
      },
      {
        "key": "blocks",
        "name": I18n.tr("wallpaper.transitions.blocks")
      },
      {
        "key": "flash",
        "name": I18n.tr("wallpaper.transitions.flash")
      },
      {
        "key": "fade",
        "name": I18n.tr("wallpaper.transitions.fade")
      },
      {
        "key": "wipe",
        "name": I18n.tr("wallpaper.transitions.wipe")
      },
      {
        "key": "disc",
        "name": I18n.tr("wallpaper.transitions.disc")
      },
      {
        "key": "stripes",
        "name": I18n.tr("wallpaper.transitions.stripes")
      },
      {
        "key": "pixelate",
        "name": I18n.tr("wallpaper.transitions.pixelate")
      },
      {
        "key": "honeycomb",
        "name": I18n.tr("wallpaper.transitions.honeycomb")
      },
      {
        "key": "none",
        "name": I18n.tr("common.none")
      }
    ]
    currentKey: root.prefs.transition
    defaultValue: Settings.getDefaultValue("wallpaperRenderer.transition")
    onSelected: key => root.prefs.transition = key
  }

  NValueSlider {
    Layout.fillWidth: true
    enabled: root.prefs.enabled && root.prefs.transition !== "none"
    label: I18n.tr("panels.wallpaper.duration-label")
    description: I18n.tr("panels.wallpaper.duration-description")
    from: 300
    to: 4000
    stepSize: 100
    showReset: true
    value: root.prefs.duration
    defaultValue: Settings.getDefaultValue("wallpaperRenderer.duration")
    onMoved: value => root.prefs.duration = Math.round(value)
    text: (root.prefs.duration / 1000).toFixed(1) + " s"
  }

  NComboBox {
    enabled: root.prefs.enabled && (root.prefs.transition === "ring" || root.prefs.transition === "random")
    label: I18n.tr("panels.wallpaper.ring-variant-label")
    description: I18n.tr("panels.wallpaper.ring-variant-description")
    model: [
      {
        "key": "ring",
        "name": I18n.tr("panels.wallpaper.ring-variant-ring")
      },
      {
        "key": "petal",
        "name": I18n.tr("panels.wallpaper.ring-variant-petal")
      },
      {
        "key": "echo",
        "name": I18n.tr("panels.wallpaper.ring-variant-echo")
      },
      {
        "key": "swirl",
        "name": I18n.tr("panels.wallpaper.ring-variant-swirl")
      }
    ]
    currentKey: root.prefs.ringVariant
    defaultValue: Settings.getDefaultValue("wallpaperRenderer.ringVariant")
    onSelected: key => root.prefs.ringVariant = key
  }

  NComboBox {
    enabled: root.prefs.enabled
    label: I18n.tr("panels.wallpaper.colors-label")
    description: I18n.tr("panels.wallpaper.colors-description")
    model: [
      {
        "key": "theme",
        "name": I18n.tr("panels.wallpaper.colors-theme")
      },
      {
        "key": "sekai",
        "name": I18n.tr("panels.wallpaper.colors-sekai")
      }
    ]
    currentKey: root.prefs.colors
    defaultValue: Settings.getDefaultValue("wallpaperRenderer.colors")
    onSelected: key => root.prefs.colors = key
  }
}
