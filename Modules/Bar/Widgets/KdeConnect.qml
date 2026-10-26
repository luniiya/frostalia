import QtQuick
import Quickshell
import "../../../Helpers/BatteryLiquid.js" as BatteryLiquid
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
  readonly property bool liquid: widgetSettings.liquid !== undefined ? widgetSettings.liquid : widgetMetadata.liquid
  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName, section)
  readonly property bool showUnread: widgetSettings.showUnread !== undefined ? widgetSettings.showUnread : widgetMetadata.showUnread
  readonly property string iconColorKey: widgetSettings.iconColor !== undefined ? widgetSettings.iconColor : widgetMetadata.iconColor
  readonly property string textColorKey: widgetSettings.textColor !== undefined ? widgetSettings.textColor : widgetMetadata.textColor

  readonly property var device: KdeConnectService.activeDevice
  readonly property bool lowBattery: KdeConnectService.online && !!device?.battery && device.battery.charge >= 0 && device.battery.charge <= Settings.data.systemMonitor.batteryWarningThreshold && !device.battery.charging

  visible: KdeConnect.widgetVisible(KdeConnectService.enabled, device, hideWhenOffline)
  readonly property var liquidState: KdeConnect.liquidState(device, Settings.data.systemMonitor.batteryWarningThreshold)
  readonly property Item anchorItem: liquid ? liquidBox : pill
  implicitWidth: visible ? (liquid ? liquidBox.width : pill.width) : 0
  implicitHeight: visible ? (liquid ? liquidBox.height : pill.height) : 0

  function openPanel(page) {
    const panel = PanelService.getPanel("kdeConnectPanel", screen);
    if (!panel)
      return;
    if (page)
      panel.openPage(page, anchorItem);
    else
      panel.toggle(anchorItem);
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

  // Liquid mode: round container, the phone battery as liquid
  Item {
    id: liquidBox
    visible: root.liquid
    anchors.centerIn: parent
    width: BatteryLiquid.containerLength(root.capsuleHeight, 1)
    height: width

    NLiquidBattery {
      anchors.fill: parent
      percentage: root.liquidState.percent
      ready: root.liquidState.ready
      charging: root.liquidState.charging
      backgroundColor: Style.widgetBackground(root.section, liquidMouseArea.containsMouse ? ShellColors.mHover : Style.capsuleColor)
      liquidColor: root.liquidState.low ? ShellColors.mError : ShellColors.mPrimary
    }

    Rectangle {
      anchors.fill: parent
      radius: width / 2
      color: "transparent"
      border.color: Style.widgetBorder(root.section, Style.capsuleBorderColor)
      border.width: Style.capsuleBorderWidth
    }

    MouseArea {
      id: liquidMouseArea
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
      cursorShape: Qt.PointingHandCursor
      onEntered: TooltipService.show(liquidBox, KdeConnectService.statusText, BarService.getTooltipDirection(root.screenName, root.section))
      onExited: TooltipService.hide()
      onClicked: mouse => {
        TooltipService.hide();
        if (mouse.button === Qt.RightButton)
          PanelService.showContextMenu(contextMenu, liquidBox, root.screen);
        else if (mouse.button === Qt.MiddleButton)
          KdeConnectService.ring();
        else
          root.openPanel("");
      }
    }
  }

  BarPill {
    id: pill
    visible: !root.liquid

    screen: root.screen
    section: root.section
    oppositeDirection: BarService.getPillDirection(root)
    customIconColor: root.lowBattery ? ShellColors.mError : ShellColors.resolveColorKeyOptional(root.iconColorKey)
    customTextColor: ShellColors.resolveColorKeyOptional(root.textColorKey)
    icon: KdeConnect.deviceIcon(root.device)
    text: KdeConnect.batteryText(root.device)
    suffix: KdeConnect.unreadSuffix(KdeConnectService.unreadCount, root.showUnread)
    autoHide: false
    forceOpen: root.displayMode === "alwaysShow" && text !== ""
    forceClose: root.displayMode === "alwaysHide" || text === ""
    onClicked: root.openPanel("")
    onMiddleClicked: KdeConnectService.ring()
    onRightClicked: PanelService.showContextMenu(contextMenu, pill, screen)
    tooltipText: ""
  }
}
