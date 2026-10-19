import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.Networking
import qs.Widgets

// Everything the home page shows before a phone is connected: helper or
// daemon missing, nothing paired yet, or the phone being offline.
ColumnLayout {
  id: root
  required property var nav
  readonly property var device: KdeConnectService.activeDevice

  spacing: Style.marginM

  KdeConnectEmptyState {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
    visible: !KdeConnectService.running || !KdeConnectService.available
    icon: "plug-x"
    title: KdeConnectService.running ? I18n.tr("kdeconnect.status.daemon-missing") : I18n.tr("kdeconnect.status.helper-missing")
    description: KdeConnectService.running ? I18n.tr("kdeconnect.status.daemon-missing-description") : I18n.tr("kdeconnect.status.helper-missing-description")
    actionText: KdeConnectService.running ? I18n.tr("kdeconnect.status.start-daemon") : ""
    actionIcon: "player-play"
    onActionClicked: Quickshell.execDetached(["kdeconnect-cli", "--refresh"])
  }

  KdeConnectEmptyState {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
    visible: KdeConnectService.available && !root.device
    icon: "device-mobile-plus"
    title: I18n.tr("kdeconnect.status.no-device")
    description: I18n.tr("kdeconnect.status.no-device-description")
  }

  KdeConnectEmptyState {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
    visible: KdeConnectService.available && !!root.device && !KdeConnectService.online
    icon: "device-mobile-off"
    title: I18n.tr("kdeconnect.status.device-offline", {
                     device: root.device?.name || ""
                   })
    description: I18n.tr("kdeconnect.status.device-offline-description")
    actionText: I18n.tr("common.refresh")
    actionIcon: "refresh"
    onActionClicked: KdeConnectService.refresh()
  }

  KdeConnectPairing {
    Layout.fillWidth: true
    visible: KdeConnectService.available && !KdeConnectService.online
  }
}
