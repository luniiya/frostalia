import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Modules.Panels.Settings
import qs.Services.Power
import qs.Services.UI
import qs.Widgets

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

  baseSize: Style.getCapsuleHeightForScreen(screen?.name, section)
  applyUiScale: false
  customRadius: Style.radiusL
  colorBgHover: Style.widgetBackground(root.section, ShellColors.mHover)
  colorBorderHover: Style.widgetBorder(root.section, Style.capsuleBorderColor)
  colorBg: Style.widgetBackground(root.section, PowerProfileService.frostaliaPerformanceMode ? ShellColors.mPrimary : Style.capsuleColor)
  colorFg: PowerProfileService.frostaliaPerformanceMode ? ShellColors.mOnPrimary : ShellColors.resolveColorKey(iconColorKey)
  border.color: Style.widgetBorder(root.section, Style.capsuleBorderColor)
  border.width: Style.capsuleBorderWidth

  icon: PowerProfileService.frostaliaPerformanceMode ? "rocket" : "rocket-off"
  tooltipText: PowerProfileService.frostaliaPerformanceMode ? I18n.tr("tooltips.frostalia-performance-enabled") : I18n.tr("tooltips.frostalia-performance-enabled")
  tooltipDirection: BarService.getTooltipDirection(screen?.name, section)
  onClicked: PowerProfileService.toggleFrostaliaPerformance()

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
