import QtQuick
import Quickshell
import "../../../Helpers/KdeConnect.js" as KdeConnect
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Modules.Panels.Settings // For SettingsPanel
import qs.Services.Networking
import qs.Services.UI
import qs.Widgets

// Phone battery, like the Battery widget but sourced from KDE Connect.
Item {
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

  readonly property string barPosition: Settings.getBarPositionForScreen(screenName, section)
  readonly property bool isBarVertical: barPosition === "left" || barPosition === "right"
  readonly property string displayMode: widgetSettings.displayMode !== undefined ? widgetSettings.displayMode : widgetMetadata.displayMode
  readonly property bool hideWhenOffline: widgetSettings.hideWhenOffline !== undefined ? widgetSettings.hideWhenOffline : widgetMetadata.hideWhenOffline
  readonly property bool showUnread: widgetSettings.showUnread !== undefined ? widgetSettings.showUnread : widgetMetadata.showUnread
  readonly property string iconColorKey: widgetSettings.iconColor !== undefined ? widgetSettings.iconColor : widgetMetadata.iconColor
  readonly property string textColorKey: widgetSettings.textColor !== undefined ? widgetSettings.textColor : widgetMetadata.textColor

  readonly property var device: KdeConnectService.activeDevice
  readonly property bool lowBattery: KdeConnectService.online && !!device?.battery && device.battery.charge >= 0 && device.battery.charge <= Settings.data.systemMonitor.batteryWarningThreshold && !device.battery.charging

  visible: KdeConnect.widgetVisible(KdeConnectService.enabled, device, hideWhenOffline)
  implicitWidth: visible ? pill.width : 0
  implicitHeight: visible ? pill.height : 0

  function openPanel(page) {
    const panel = PanelService.getPanel("kdeConnectPanel", screen);
    if (!panel)
      return;
    if (page)
      panel.openPage(page, pill);
    else
      panel.toggle(pill);
  }

  NPopupContextMenu {
    id: contextMenu

    model: [
      {
        "label": I18n.tr("kdeconnect.actions.ring"),
        "action": "ring",
        "icon": "bell-ringing",
        "enabled": KdeConnectService.online
      },
      {
        "label": I18n.tr("kdeconnect.messages.title"),
        "action": "messages",
        "icon": "messages",
        "enabled": KdeConnectService.online
      },
      {
        "label": I18n.tr("kdeconnect.actions.share"),
        "action": "share",
        "icon": "file-upload",
        "enabled": KdeConnectService.online
      },
      {
        "label": I18n.tr("kdeconnect.title") + " " + I18n.tr("tooltips.open-settings"),
        "action": "settings",
        "icon": "settings"
      },
      {
        "label": I18n.tr("actions.widget-settings"),
        "action": "widget-settings",
        "icon": "settings"
      }
    ]

    onTriggered: action => {
      contextMenu.close();
      PanelService.closeContextMenu(screen);
      if (action === "ring") {
        KdeConnectService.ring();
      } else if (action === "messages") {
        root.openPanel("messages");
      } else if (action === "share") {
        root.openPanel("files");
      } else if (action === "settings") {
        SettingsPanelService.openToTab(SettingsPanel.Tab.Connections, 2, screen);
      } else if (action === "widget-settings") {
        BarService.openWidgetSettings(screen, section, sectionWidgetIndex, widgetId, widgetSettings);
      }
    }
  }

  BarPill {
    id: pill

    screen: root.screen
    section: root.section
    oppositeDirection: BarService.getPillDirection(root)
    customIconColor: root.lowBattery ? Color.mError : Color.resolveColorKeyOptional(root.iconColorKey)
    customTextColor: Color.resolveColorKeyOptional(root.textColorKey)
    icon: KdeConnect.deviceIcon(root.device)
    text: KdeConnect.batteryText(root.device)
    suffix: KdeConnect.unreadSuffix(KdeConnectService.unreadCount, root.showUnread)
    autoHide: false
    forceOpen: !isBarVertical && root.displayMode === "alwaysShow" && text !== ""
    forceClose: isBarVertical || root.displayMode === "alwaysHide" || text === ""
    onClicked: root.openPanel("")
    onMiddleClicked: KdeConnectService.ring()
    onRightClicked: PanelService.showContextMenu(contextMenu, pill, screen)
    tooltipText: ""
  }
}
