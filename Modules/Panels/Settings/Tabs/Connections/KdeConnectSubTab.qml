import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services.Networking
import qs.Services.UI
import qs.Widgets

ColumnLayout {
  id: root
  Layout.fillWidth: true
  spacing: Style.marginL

  NToggle {
    label: I18n.tr("panels.connections.kdeconnect-enabled-label")
    description: I18n.tr("panels.connections.kdeconnect-enabled-description")
    icon: "device-mobile"
    checked: Settings.data.kdeConnect.enabled
    defaultValue: Settings.getDefaultValue("kdeConnect.enabled")
    onToggled: checked => Settings.data.kdeConnect.enabled = checked
  }

  NText {
    Layout.fillWidth: true
    visible: Settings.data.kdeConnect.enabled
    text: {
      if (!KdeConnectService.running)
        return I18n.tr("kdeconnect.status.helper-missing");
      if (!KdeConnectService.available)
        return I18n.tr("kdeconnect.status.daemon-missing");
      const device = KdeConnectService.activeDevice;
      if (!device)
        return I18n.tr("kdeconnect.status.no-device");
      return KdeConnectService.online ? I18n.tr("kdeconnect.status.connected-to", {
                                                  device: device.name
                                                }) : I18n.tr("kdeconnect.status.device-offline", {
                                                               device: device.name
                                                             });
    }
    pointSize: Style.fontSizeS
    color: KdeConnectService.online ? Color.mPrimary : Color.mOnSurfaceVariant
    wrapMode: Text.Wrap
  }

  NValueSlider {
    Layout.fillWidth: true
    visible: Settings.data.kdeConnect.enabled
    label: I18n.tr("panels.connections.kdeconnect-touchpad-sensitivity-label")
    description: I18n.tr("panels.connections.kdeconnect-touchpad-sensitivity-description")
    from: 0.5
    to: 4
    stepSize: 0.1
    showReset: true
    value: Settings.data.kdeConnect.touchpadSensitivity
    defaultValue: Settings.getDefaultValue("kdeConnect.touchpadSensitivity")
    onMoved: value => Settings.data.kdeConnect.touchpadSensitivity = value
    text: Settings.data.kdeConnect.touchpadSensitivity.toFixed(1) + "×"
  }

  NText {
    Layout.fillWidth: true
    text: I18n.tr("panels.connections.kdeconnect-widgets-hint")
    pointSize: Style.fontSizeXS
    color: Color.mOnSurfaceVariant
    wrapMode: Text.Wrap
  }
}
