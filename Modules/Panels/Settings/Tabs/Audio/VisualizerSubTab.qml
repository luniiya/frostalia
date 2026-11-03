import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../../../../Helpers/WallpaperVisualizer.js" as WallpaperVisualizer
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginL
  Layout.fillWidth: true

  NComboBox {
    label: I18n.tr("panels.audio.visualizer-type-label")
    description: I18n.tr("panels.audio.visualizer-type-description")
    model: [
      {
        "key": "none",
        "name": I18n.tr("common.none")
      },
      {
        "key": "linear",
        "name": I18n.tr("options.visualizer-types.linear")
      },
      {
        "key": "mirrored",
        "name": I18n.tr("options.visualizer-types.mirrored")
      },
      {
        "key": "wave",
        "name": I18n.tr("options.visualizer-types.wave")
      }
    ]
    currentKey: Settings.data.audio.visualizerType
    defaultValue: Settings.getDefaultValue("audio.visualizerType")
    onSelected: key => Settings.data.audio.visualizerType = key
  }

  NToggle {
    label: I18n.tr("panels.audio.spectrum-mirrored-label")
    description: I18n.tr("panels.audio.spectrum-mirrored-description")
    checked: Settings.data.audio.spectrumMirrored
    defaultValue: Settings.getDefaultValue("audio.spectrumMirrored")
    onToggled: Settings.data.audio.spectrumMirrored = checked
  }

  NComboBox {
    label: I18n.tr("panels.audio.media-frame-rate-label")
    description: I18n.tr("panels.audio.media-frame-rate-description")
    model: [
      {
        "key": "30",
        "name": I18n.tr("options.frame-rates-fps", {
                          "fps": "30"
                        })
      },
      {
        "key": "60",
        "name": I18n.tr("options.frame-rates-fps", {
                          "fps": "60"
                        })
      },
      {
        "key": "100",
        "name": I18n.tr("options.frame-rates-fps", {
                          "fps": "100"
                        })
      },
      {
        "key": "120",
        "name": I18n.tr("options.frame-rates-fps", {
                          "fps": "120"
                        })
      },
      {
        "key": "144",
        "name": I18n.tr("options.frame-rates-fps", {
                          "fps": "144"
                        })
      },
      {
        "key": "165",
        "name": I18n.tr("options.frame-rates-fps", {
                          "fps": "165"
                        })
      },
      {
        "key": "240",
        "name": I18n.tr("options.frame-rates-fps", {
                          "fps": "240"
                        })
      }
    ]
    currentKey: Settings.data.audio.spectrumFrameRate
    defaultValue: Settings.getDefaultValue("audio.spectrumFrameRate")
    onSelected: key => Settings.data.audio.spectrumFrameRate = key
  }

  NDivider {
    Layout.fillWidth: true
  }

  NHeader {
    label: I18n.tr("panels.audio.wallpaper-visualizer-title")
    description: I18n.tr("panels.audio.wallpaper-visualizer-desc")
  }

  NToggle {
    label: I18n.tr("panels.audio.wallpaper-visualizer-enabled-label")
    description: I18n.tr("panels.audio.wallpaper-visualizer-enabled-description")
    checked: Settings.data.wallpaperVisualizer.enabled
    defaultValue: Settings.getDefaultValue("wallpaperVisualizer.enabled")
    onToggled: checked => Settings.data.wallpaperVisualizer.enabled = checked
  }

  NComboBox {
    enabled: Settings.data.wallpaperVisualizer.enabled
    label: I18n.tr("panels.audio.wallpaper-visualizer-edges-label")
    description: I18n.tr("panels.audio.wallpaper-visualizer-edges-description")
    model: [
      {
        "key": "all",
        "name": I18n.tr("panels.audio.wallpaper-visualizer-edges-all")
      },
      {
        "key": "topBottom",
        "name": I18n.tr("panels.audio.wallpaper-visualizer-edges-top-bottom")
      },
      {
        "key": "leftRight",
        "name": I18n.tr("panels.audio.wallpaper-visualizer-edges-left-right")
      },
      {
        "key": "top",
        "name": I18n.tr("panels.audio.wallpaper-visualizer-edges-top")
      },
      {
        "key": "bottom",
        "name": I18n.tr("panels.audio.wallpaper-visualizer-edges-bottom")
      },
      {
        "key": "left",
        "name": I18n.tr("panels.audio.wallpaper-visualizer-edges-left")
      },
      {
        "key": "right",
        "name": I18n.tr("panels.audio.wallpaper-visualizer-edges-right")
      }
    ]
    currentKey: Settings.data.wallpaperVisualizer.edges
    defaultValue: Settings.getDefaultValue("wallpaperVisualizer.edges")
    onSelected: key => Settings.data.wallpaperVisualizer.edges = key
  }

  NValueSlider {
    Layout.fillWidth: true
    enabled: Settings.data.wallpaperVisualizer.enabled
    label: I18n.tr("panels.audio.wallpaper-visualizer-height-label")
    description: I18n.tr("panels.audio.wallpaper-visualizer-height-description")
    from: WallpaperVisualizer.heightRange[0]
    to: WallpaperVisualizer.heightRange[1]
    stepSize: 0.01
    showReset: true
    value: Settings.data.wallpaperVisualizer.height
    defaultValue: Settings.getDefaultValue("wallpaperVisualizer.height")
    onMoved: value => Settings.data.wallpaperVisualizer.height = value
    text: Math.round(Settings.data.wallpaperVisualizer.height * 100) + "%"
  }

  NValueSlider {
    Layout.fillWidth: true
    enabled: Settings.data.wallpaperVisualizer.enabled
    label: I18n.tr("panels.audio.wallpaper-visualizer-opacity-label")
    description: I18n.tr("panels.audio.wallpaper-visualizer-opacity-description")
    from: WallpaperVisualizer.opacityRange[0]
    to: WallpaperVisualizer.opacityRange[1]
    stepSize: 0.01
    showReset: true
    value: Settings.data.wallpaperVisualizer.opacity
    defaultValue: Settings.getDefaultValue("wallpaperVisualizer.opacity")
    onMoved: value => Settings.data.wallpaperVisualizer.opacity = value
    text: Math.round(Settings.data.wallpaperVisualizer.opacity * 100) + "%"
  }

  NValueSlider {
    Layout.fillWidth: true
    enabled: Settings.data.wallpaperVisualizer.enabled
    label: I18n.tr("panels.audio.wallpaper-visualizer-whiteness-label")
    description: I18n.tr("panels.audio.wallpaper-visualizer-whiteness-description")
    from: WallpaperVisualizer.whitenessRange[0]
    to: WallpaperVisualizer.whitenessRange[1]
    stepSize: 0.01
    showReset: true
    value: Settings.data.wallpaperVisualizer.whiteness
    defaultValue: Settings.getDefaultValue("wallpaperVisualizer.whiteness")
    onMoved: value => Settings.data.wallpaperVisualizer.whiteness = value
    text: Math.round(Settings.data.wallpaperVisualizer.whiteness * 100) + "%"
  }

  NValueSlider {
    Layout.fillWidth: true
    enabled: Settings.data.wallpaperVisualizer.enabled
    label: I18n.tr("panels.audio.wallpaper-visualizer-rim-label")
    description: I18n.tr("panels.audio.wallpaper-visualizer-rim-description")
    from: WallpaperVisualizer.rimRange[0]
    to: WallpaperVisualizer.rimRange[1]
    stepSize: 0.01
    showReset: true
    value: Settings.data.wallpaperVisualizer.rim
    defaultValue: Settings.getDefaultValue("wallpaperVisualizer.rim")
    onMoved: value => Settings.data.wallpaperVisualizer.rim = value
    text: Math.round(Settings.data.wallpaperVisualizer.rim * 100) + "%"
  }

  NValueSlider {
    Layout.fillWidth: true
    enabled: Settings.data.wallpaperVisualizer.enabled
    label: I18n.tr("panels.audio.wallpaper-visualizer-back-wave-label")
    description: I18n.tr("panels.audio.wallpaper-visualizer-back-wave-description")
    from: WallpaperVisualizer.backWaveRange[0]
    to: WallpaperVisualizer.backWaveRange[1]
    stepSize: 0.01
    showReset: true
    value: Settings.data.wallpaperVisualizer.backWave
    defaultValue: Settings.getDefaultValue("wallpaperVisualizer.backWave")
    onMoved: value => Settings.data.wallpaperVisualizer.backWave = value
    text: Math.round(Settings.data.wallpaperVisualizer.backWave * 100) + "%"
  }

  NValueSlider {
    Layout.fillWidth: true
    enabled: Settings.data.wallpaperVisualizer.enabled
    label: I18n.tr("panels.audio.wallpaper-visualizer-softness-label")
    description: I18n.tr("panels.audio.wallpaper-visualizer-softness-description")
    from: WallpaperVisualizer.softnessRange[0]
    to: WallpaperVisualizer.softnessRange[1]
    stepSize: 0.01
    showReset: true
    value: Settings.data.wallpaperVisualizer.softness
    defaultValue: Settings.getDefaultValue("wallpaperVisualizer.softness")
    onMoved: value => Settings.data.wallpaperVisualizer.softness = value
    text: Math.round(Settings.data.wallpaperVisualizer.softness * 100) + "%"
  }

  NColorChoice {
    Layout.fillWidth: true
    enabled: Settings.data.wallpaperVisualizer.enabled
    label: I18n.tr("panels.audio.wallpaper-visualizer-color-label")
    description: I18n.tr("panels.audio.wallpaper-visualizer-color-description")
    currentKey: Settings.data.wallpaperVisualizer.color
    defaultValue: Settings.getDefaultValue("wallpaperVisualizer.color")
    onSelected: key => Settings.data.wallpaperVisualizer.color = key
  }

  NToggle {
    enabled: Settings.data.wallpaperVisualizer.enabled
    label: I18n.tr("panels.audio.wallpaper-visualizer-depth-label")
    description: I18n.tr("panels.audio.wallpaper-visualizer-depth-description")
    checked: Settings.data.wallpaperVisualizer.depth
    defaultValue: Settings.getDefaultValue("wallpaperVisualizer.depth")
    onToggled: checked => Settings.data.wallpaperVisualizer.depth = checked
  }
}
