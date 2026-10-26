import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Services.System
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginL
  Layout.fillWidth: true

  NSearchableComboBox {
    label: I18n.tr("panels.general.fonts-default-label")
    description: I18n.tr("panels.general.fonts-default-description")
    model: FontService.availableFonts
    currentKey: Settings.data.ui.fontDefault
    placeholder: I18n.tr("panels.general.fonts-default-placeholder")
    searchPlaceholder: I18n.tr("panels.general.fonts-default-search-placeholder")
    popupHeight: 420
    defaultValue: Settings.getDefaultValue("ui.fontDefault")
    settingsPath: "ui.fontDefault"
    onSelected: key => Settings.data.ui.fontDefault = key
  }

  NSearchableComboBox {
    label: I18n.tr("panels.general.fonts-monospace-label")
    description: I18n.tr("panels.general.fonts-monospace-description")
    model: FontService.monospaceFonts
    currentKey: Settings.data.ui.fontFixed
    placeholder: I18n.tr("panels.general.fonts-monospace-placeholder")
    searchPlaceholder: I18n.tr("panels.general.fonts-monospace-search-placeholder")
    popupHeight: 320
    defaultValue: Settings.getDefaultValue("ui.fontFixed")
    settingsPath: "ui.fontFixed"
    onSelected: key => Settings.data.ui.fontFixed = key
  }

  NToggle {
    label: I18n.tr("panels.user-interface.tooltips-label")
    description: I18n.tr("panels.user-interface.tooltips-description")
    checked: Settings.data.ui.tooltipsEnabled
    defaultValue: Settings.getDefaultValue("ui.tooltipsEnabled")
    onToggled: checked => Settings.data.ui.tooltipsEnabled = checked
  }

  NToggle {
    label: I18n.tr("panels.user-interface.box-border-label")
    description: I18n.tr("panels.user-interface.box-border-description")
    checked: Settings.data.ui.boxBorderEnabled
    defaultValue: Settings.getDefaultValue("ui.boxBorderEnabled")
    onToggled: checked => Settings.data.ui.boxBorderEnabled = checked
  }

  NValueSlider {
    visible: Settings.data.ui.boxBorderEnabled
    Layout.fillWidth: true
    label: I18n.tr("panels.user-interface.box-border-width-label")
    description: I18n.tr("panels.user-interface.box-border-width-description")
    from: 1
    to: 6
    stepSize: 1
    showReset: true
    value: Settings.data.ui.boxBorderWidth
    defaultValue: Settings.getDefaultValue("ui.boxBorderWidth")
    onMoved: value => Settings.data.ui.boxBorderWidth = Math.round(value)
    text: Settings.data.ui.boxBorderWidth + "px"
  }

  NColorChoice {
    visible: Settings.data.ui.boxBorderEnabled
    label: I18n.tr("panels.user-interface.box-border-color-label")
    description: I18n.tr("panels.user-interface.box-border-color-description")
    model: [
      {
        "key": "outline",
        "name": I18n.tr("panels.user-interface.box-border-color-outline")
      },
      {
        "key": "primary",
        "name": I18n.tr("common.primary")
      },
      {
        "key": "secondary",
        "name": I18n.tr("common.secondary")
      },
      {
        "key": "tertiary",
        "name": I18n.tr("common.tertiary")
      },
      {
        "key": "error",
        "name": I18n.tr("common.error")
      }
    ]
    currentKey: Settings.data.ui.boxBorderColor
    defaultValue: Settings.getDefaultValue("ui.boxBorderColor")
    onSelected: key => Settings.data.ui.boxBorderColor = key
  }

  NValueSlider {
    visible: Settings.data.ui.boxBorderEnabled
    Layout.fillWidth: true
    label: I18n.tr("panels.user-interface.box-border-brightness-label")
    description: I18n.tr("panels.user-interface.box-border-brightness-description")
    from: -100
    to: 100
    stepSize: 5
    showReset: true
    value: Settings.data.ui.boxBorderBrightness
    defaultValue: Settings.getDefaultValue("ui.boxBorderBrightness")
    onMoved: value => Settings.data.ui.boxBorderBrightness = Math.round(value)
    text: (Settings.data.ui.boxBorderBrightness > 0 ? "+" : "") + Settings.data.ui.boxBorderBrightness
  }

  NValueSlider {
    visible: Settings.data.ui.boxBorderEnabled
    Layout.fillWidth: true
    label: I18n.tr("panels.user-interface.box-border-opacity-label")
    description: I18n.tr("panels.user-interface.box-border-opacity-description")
    from: 0
    to: 100
    stepSize: 5
    showReset: true
    value: Settings.data.ui.boxBorderOpacity
    defaultValue: Settings.getDefaultValue("ui.boxBorderOpacity")
    onMoved: value => Settings.data.ui.boxBorderOpacity = Math.round(value)
    text: Settings.data.ui.boxBorderOpacity + "%"
  }

  NToggle {
    label: I18n.tr("panels.user-interface.scrollbar-always-visible-label")
    description: I18n.tr("panels.user-interface.scrollbar-always-visible-description")
    checked: Settings.data.ui.scrollbarAlwaysVisible
    defaultValue: Settings.getDefaultValue("ui.scrollbarAlwaysVisible")
    onToggled: checked => Settings.data.ui.scrollbarAlwaysVisible = checked
  }

  NToggle {
    label: I18n.tr("panels.user-interface.shadows-label")
    description: I18n.tr("panels.user-interface.shadows-description")
    checked: Settings.data.general.enableShadows
    defaultValue: Settings.getDefaultValue("general.enableShadows")
    onToggled: checked => Settings.data.general.enableShadows = checked
  }

  NToggle {
    label: I18n.tr("panels.user-interface.blur-behind-label")
    description: I18n.tr("panels.user-interface.blur-behind-description")
    checked: Settings.data.general.enableBlurBehind
    defaultValue: Settings.getDefaultValue("general.enableBlurBehind")
    onToggled: checked => Settings.data.general.enableBlurBehind = checked
  }

  NToggle {
    visible: !!Style.uiStyleTokens.frostedGlass
    label: I18n.tr("panels.user-interface.frosted-glass-label")
    description: I18n.tr("panels.user-interface.frosted-glass-description")
    checked: Settings.data.ui.frostedGlass
    defaultValue: Settings.getDefaultValue("ui.frostedGlass")
    onToggled: checked => Settings.data.ui.frostedGlass = checked
  }

  NValueSlider {
    Layout.fillWidth: true
    visible: !!Style.uiStyleTokens.frostedGlass && Settings.data.ui.frostedGlass
    enabled: Style.glass !== null
    label: I18n.tr("panels.user-interface.glass-panel-opacity-label")
    description: I18n.tr("panels.user-interface.glass-panel-opacity-description")
    from: 0
    to: 1
    stepSize: 0.01
    showReset: true
    value: Settings.data.ui.glassPanelOpacity
    defaultValue: Settings.getDefaultValue("ui.glassPanelOpacity")
    onMoved: value => Settings.data.ui.glassPanelOpacity = value
    text: Math.round(Settings.data.ui.glassPanelOpacity * 100) + "%"
  }

  NValueSlider {
    Layout.fillWidth: true
    visible: !!Style.uiStyleTokens.frostedGlass && Settings.data.ui.frostedGlass
    enabled: Style.glass !== null
    label: I18n.tr("panels.user-interface.glass-surface-opacity-label")
    description: I18n.tr("panels.user-interface.glass-surface-opacity-description")
    from: 0
    to: 1
    stepSize: 0.01
    showReset: true
    value: Settings.data.ui.glassSurfaceOpacity
    defaultValue: Settings.getDefaultValue("ui.glassSurfaceOpacity")
    onMoved: value => Settings.data.ui.glassSurfaceOpacity = value
    text: Math.round(Settings.data.ui.glassSurfaceOpacity * 100) + "%"
  }

  NToggle {
    enabled: Style.glass === null
    label: I18n.tr("panels.user-interface.translucent-widgets-label")
    description: I18n.tr("panels.user-interface.translucent-widgets-description")
    checked: Settings.data.ui.translucentWidgets
    defaultValue: Settings.getDefaultValue("ui.translucentWidgets")
    onToggled: checked => Settings.data.ui.translucentWidgets = checked
  }

  NComboBox {
    visible: Settings.data.general.enableShadows
    label: I18n.tr("panels.user-interface.shadows-direction-label")
    description: I18n.tr("panels.user-interface.shadows-direction-description")
    Layout.fillWidth: true

    readonly property var shadowOptionsMap: ({
                                               "top_left": {
                                                 "name": I18n.tr("positions.top-left"),
                                                 "p": Qt.point(-2, -2)
                                               },
                                               "top": {
                                                 "name": I18n.tr("positions.top"),
                                                 "p": Qt.point(0, -3)
                                               },
                                               "top_right": {
                                                 "name": I18n.tr("positions.top-right"),
                                                 "p": Qt.point(2, -2)
                                               },
                                               "left": {
                                                 "name": I18n.tr("positions.left"),
                                                 "p": Qt.point(-3, 0)
                                               },
                                               "center": {
                                                 "name": I18n.tr("positions.center"),
                                                 "p": Qt.point(0, 0)
                                               },
                                               "right": {
                                                 "name": I18n.tr("positions.right"),
                                                 "p": Qt.point(3, 0)
                                               },
                                               "bottom_left": {
                                                 "name": I18n.tr("positions.bottom-left"),
                                                 "p": Qt.point(-2, 2)
                                               },
                                               "bottom": {
                                                 "name": I18n.tr("positions.bottom"),
                                                 "p": Qt.point(0, 3)
                                               },
                                               "bottom_right": {
                                                 "name": I18n.tr("positions.bottom-right"),
                                                 "p": Qt.point(2, 3)
                                               }
                                             })

    model: Object.keys(shadowOptionsMap).map(function (k) {
      return {
        "key": k,
        "name": shadowOptionsMap[k].name
      };
    })

    currentKey: Settings.data.general.shadowDirection
    defaultValue: Settings.getDefaultValue("general.shadowDirection")

    onSelected: function (key) {
      var opt = shadowOptionsMap[key];
      if (opt) {
        Settings.data.general.shadowDirection = key;
        Settings.data.general.shadowOffsetX = opt.p.x;
        Settings.data.general.shadowOffsetY = opt.p.y;
      }
    }
  }

  NDivider {
    Layout.fillWidth: true
  }

  NValueSlider {
    Layout.fillWidth: true
    label: I18n.tr("panels.user-interface.box-border-radius-label")
    description: I18n.tr("panels.user-interface.box-border-radius-description")
    from: 0
    to: 2
    stepSize: 0.01
    showReset: true
    value: Settings.data.general.radiusRatio
    defaultValue: Settings.getDefaultValue("general.radiusRatio")
    onMoved: value => Settings.data.general.radiusRatio = value
    text: Math.floor(Settings.data.general.radiusRatio * 100) + "%"
  }

  NValueSlider {
    Layout.fillWidth: true
    label: I18n.tr("panels.user-interface.control-border-radius-label")
    description: I18n.tr("panels.user-interface.control-border-radius-description")
    from: 0
    to: 2
    stepSize: 0.01
    showReset: true
    value: Settings.data.general.iRadiusRatio
    defaultValue: Settings.getDefaultValue("general.iRadiusRatio")
    onMoved: value => Settings.data.general.iRadiusRatio = value
    text: Math.floor(Settings.data.general.iRadiusRatio * 100) + "%"
  }

  NDivider {
    Layout.fillWidth: true
  }

  ColumnLayout {
    spacing: Style.marginL
    Layout.fillWidth: true

    NToggle {
      label: I18n.tr("panels.user-interface.animation-disable-label")
      description: I18n.tr("panels.user-interface.animation-disable-description")
      checked: Settings.data.general.animationDisabled
      defaultValue: Settings.getDefaultValue("general.animationDisabled")
      onToggled: checked => Settings.data.general.animationDisabled = checked
    }

    ColumnLayout {
      spacing: Style.marginXXS
      Layout.fillWidth: true
      visible: !Settings.data.general.animationDisabled

      NValueSlider {
        Layout.fillWidth: true
        label: I18n.tr("panels.user-interface.animation-speed-label")
        description: I18n.tr("panels.user-interface.animation-speed-description")
        from: 0
        to: 2.0
        stepSize: 0.01
        showReset: true
        value: Settings.data.general.animationSpeed
        defaultValue: Settings.getDefaultValue("general.animationSpeed")
        onMoved: value => Settings.data.general.animationSpeed = Math.max(value, 0.05)
        text: Math.round(Settings.data.general.animationSpeed * 100) + "%"
      }
    }
  }
}
