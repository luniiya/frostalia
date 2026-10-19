import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../../Helpers/ControlCenterLayout.js" as ControlCenterLayout
import qs.Commons
import qs.Services.Networking
import qs.Widgets

MaterialTile {
  id: root
  required property var entry
  required property var screen
  readonly property var action: controller.action
  readonly property bool actionable: !!action && typeof action.clicked === "function"
  readonly property string widgetId: entry.settings.id

  wide: entry.span === 2
  available: !action || action.enabled !== false
  interactive: actionable
  showContent: actionable
  icon: action?.icon || "settings"
  active: {
    switch (widgetId) {
    case "Network":
    case "WiFi":
      return NetworkService.wifiEnabled || NetworkService.ethernetConnected;
    case "Bluetooth":
      return BluetoothService.enabled;
    case "DarkMode":
      return Settings.data.colorSchemes.darkMode;
    case "KdeConnect":
      return KdeConnectService.online;
    default:
      return action?.hot || false;
    }
  }
  title: {
    switch (widgetId) {
    case "Network":
    case "WiFi":
      return NetworkService.ethernetConnected ? I18n.tr("control-center.wifi.label-ethernet") : I18n.tr("common.wifi");
    case "Bluetooth":
      return I18n.tr("common.bluetooth");
    case "PowerProfile":
      return I18n.tr("battery.power-profile");
    case "KdeConnect":
      return KdeConnectService.activeDevice?.name || I18n.tr("kdeconnect.title");
    default:
      return String(action?.tooltipText || widgetId).split("\n")[0];
    }
  }
  subtitle: {
    if (widgetId === "Network" || widgetId === "WiFi")
      return NetworkService.getStatusText(true);
    if (widgetId === "Bluetooth")
      return BluetoothService.connectedDevices.length ? I18n.tr("common.connected") : I18n.tr("common.disconnected");
    if (widgetId === "KdeConnect")
      return action?.statusText || "";
    return I18n.tr(active ? "common.enabled" : "common.disabled");
  }
  onClicked: button => ControlCenterLayout.invoke(action, button)

  ControlCenterWidgetLoader {
    id: controller
    anchors.centerIn: parent
    visible: !root.actionable
    widgetId: root.widgetId
    widgetScreen: root.screen
    widgetProps: ({
                    widgetId: root.widgetId,
                    section: "quickSettings",
                    sectionWidgetIndex: root.entry.index,
                    widgetSettings: root.entry.settings
                  })
  }
}
