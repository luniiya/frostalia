import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Commons
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
  // Explicit screenName property ensures reactive binding when screen changes
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

  readonly property string valueIconColor: widgetSettings.iconColor !== undefined ? widgetSettings.iconColor : widgetMetadata.iconColor

  readonly property color iconColor: Color.resolveColorKey(valueIconColor)

  icon: "settings"
  tooltipText: {
    if (SettingsPanelService.isWindowOpen) {
      return "";
    } else {
      return I18n.tr("tooltips.open-settings");
    }
  }
  tooltipDirection: BarService.getTooltipDirection(screen?.name, section)
  baseSize: Style.getCapsuleHeightForScreen(screen?.name, section)
  applyUiScale: false
  customRadius: Style.radiusL
  colorBg: Style.widgetBackground(root.section, Style.capsuleColor)
  colorFg: iconColor
  colorBgHover: Style.widgetBackground(root.section, Color.mHover)
  colorFgHover: Color.mOnHover
  colorBorder: Style.widgetBorder(root.section, Style.capsuleBorderColor)
  colorBorderHover: Style.widgetBorder(root.section, Style.capsuleBorderColor)

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

  onClicked: {
    PanelService.getPanel("settingsPanel", screen)?.toggle();
  }
  onRightClicked: {
    PanelService.showContextMenu(contextMenu, root, screen);
  }
}
