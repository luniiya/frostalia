import QtQuick
import Quickshell
import qs.Commons
import qs.Services.Power
import qs.Services.UI
import qs.Widgets

// Eco (lite) mode toggle; power saver forces it on
NIconButton {
  id: root

  property ShellScreen screen

  // Widget properties passed from Bar.qml for per-instance settings
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  property var widgetMetadata: BarWidgetRegistry.widgetMetadata[widgetId] ?? {}
  readonly property string screenName: screen ? screen.name : ""
  property var widgetSettings: {
    if (section && sectionWidgetIndex >= 0 && screenName) {
      var widgets = Settings.getBarWidgetsForScreen(screenName, section)[section];
      if (widgets && sectionWidgetIndex < widgets.length) {
        return widgets[sectionWidgetIndex];
      }
    }
    return {};
  }

  readonly property string iconColorKey: widgetSettings.iconColor !== undefined ? widgetSettings.iconColor : widgetMetadata.iconColor
  readonly property bool on: PowerProfileService.ecoMode

  baseSize: Style.getCapsuleHeightForScreen(screen?.name, section)
  faceView: "EcoMode"
  faceDepth: Style.barFaceDepth(screen?.name, section)
  faceData: ({
               "on": root.on,
               "forced": PowerProfileService.ecoModeForced
             })
  applyUiScale: false
  customRadius: Style.radiusL
  icon: "bolt"
  tooltipText: PowerProfileService.ecoModeForced ? I18n.tr("tooltips.eco-mode-forced") : I18n.tr("tooltips.eco-mode")
  tooltipDirection: BarService.getTooltipDirection(screen?.name, section)
  colorBgHover: Style.widgetBackground(root.section, ShellColors.mHover)
  colorBorderHover: Style.widgetBorder(root.section, Style.capsuleBorderColor)
  colorBg: Style.widgetBackground(root.section, root.on ? ShellColors.mPrimary : Style.capsuleColor)
  colorFg: root.on ? ShellColors.mOnPrimary : ShellColors.resolveColorKey(iconColorKey)
  border.color: Style.widgetBorder(root.section, Style.capsuleBorderColor)
  border.width: Style.capsuleBorderWidth
  onClicked: PowerProfileService.toggleEcoMode()

  NPopupContextMenu {
    id: contextMenu

    model: [
      {
        "label": I18n.tr("actions.widget-settings"),
        "action": "widget-settings",
        "icon": "settings"
      },
    ]

    onTriggered: action => {
      contextMenu.close();
      PanelService.closeContextMenu(screen);

      if (action === "widget-settings") {
        BarService.openWidgetSettings(screen, section, sectionWidgetIndex, widgetId, widgetSettings);
      }
    }
  }

  onRightClicked: {
    PanelService.showContextMenu(contextMenu, root, screen);
  }
}
