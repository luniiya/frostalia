import QtQuick.Layouts
import Quickshell
import "../../../../Helpers/KdeConnect.js" as KdeConnect
import qs.Commons
import qs.Modules.Panels.Settings
import qs.Services.Networking
import qs.Services.UI
import qs.Widgets

// Phone shortcut: opens the KDE Connect panel, right click rings the phone.
NIconButtonHot {
  property ShellScreen screen

  // Subtitle of the wide Material tile.
  readonly property string statusText: {
    if (!KdeConnectService.enabled)
      return I18n.tr("common.disabled");
    if (!KdeConnectService.online)
      return I18n.tr("kdeconnect.status.offline");
    const battery = KdeConnect.batteryText(KdeConnectService.activeDevice);
    return battery ? I18n.tr("kdeconnect.status.battery", {
                               battery: battery
                             }) : I18n.tr("common.connected");
  }

  icon: KdeConnect.deviceIcon(KdeConnectService.activeDevice)
  hot: KdeConnectService.online
  tooltipText: I18n.tr("kdeconnect.title")
  onClicked: {
    if (!KdeConnectService.enabled) {
      PanelService.getPanel("controlCenterPanel", screen)?.close();
      SettingsPanelService.openToTab(SettingsPanel.Tab.Connections, 2, screen);
      return;
    }
    PanelService.getPanel("kdeConnectPanel", screen)?.toggle(this);
  }
  onRightClicked: KdeConnectService.ring()
}
