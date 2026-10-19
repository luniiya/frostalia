import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../../Helpers/ControlCenterLayout.js" as ControlCenterLayout
import qs.Commons
import qs.Services.Networking
import qs.Widgets

Rectangle {
  id: root
  required property var entry
  required property var screen
  property bool wide: entry.span === 2
  readonly property var action: controller.action
  readonly property bool actionable: !!action && typeof action.clicked === "function"
  readonly property bool available: !action || action.enabled !== false
  readonly property string widgetId: entry.settings.id
  readonly property bool active: {
    switch (widgetId) {
    case "Network":
    case "WiFi":
      return NetworkService.wifiEnabled || NetworkService.ethernetConnected;
    case "Bluetooth":
      return BluetoothService.enabled;
    case "DarkMode":
      return Settings.data.colorSchemes.darkMode;
    default:
      return action?.hot || false;
    }
  }
  readonly property string title: {
    switch (widgetId) {
    case "Network":
    case "WiFi":
      return NetworkService.ethernetConnected ? I18n.tr("control-center.wifi.label-ethernet") : I18n.tr("common.wifi");
    case "Bluetooth":
      return I18n.tr("common.bluetooth");
    case "PowerProfile":
      return I18n.tr("battery.power-profile");
    default:
      return String(action?.tooltipText || widgetId).split("\n")[0];
    }
  }
  readonly property string subtitle: {
    if (widgetId === "Network" || widgetId === "WiFi")
      return NetworkService.getStatusText(true);
    if (widgetId === "Bluetooth")
      return BluetoothService.connectedDevices.length ? I18n.tr("common.connected") : I18n.tr("common.disconnected");
    return I18n.tr(active ? "common.enabled" : "common.disabled");
  }
  implicitHeight: Math.round(60 * Style.uiScaleRatio)
  radius: Math.min(Style.iRadiusL, height / 2)
  color: active ? Color.mPrimary : Qt.tint(Color.mSurfaceVariant, Qt.alpha(Color.mOnSurface, 0.035))
  opacity: available ? 1 : 0.45
  Accessible.name: title + ", " + subtitle
  Accessible.role: Accessible.Button
  Accessible.onPressAction: ControlCenterLayout.invoke(action, "left")

  NMaterialStateLayer {
    hovered: pointer.containsMouse
    pressed: pointer.pressed
    tint: root.active ? Color.mOnPrimary : Color.mOnSurface
  }

  RowLayout {
    anchors.fill: parent
    anchors.margins: Math.round(12 * Style.uiScaleRatio)
    spacing: Style.marginM
    visible: root.actionable
    NIcon {
      Layout.alignment: Qt.AlignCenter
      Layout.fillWidth: !root.wide
      horizontalAlignment: Text.AlignHCenter
      icon: root.action?.icon || "settings"
      pointSize: Style.fontSizeXL
      color: root.active ? Color.mOnPrimary : Color.mOnSurface
    }
    ColumnLayout {
      visible: root.wide
      Layout.fillWidth: true
      Layout.minimumWidth: 0
      spacing: 0
      NText {
        Layout.fillWidth: true
        text: root.title
        pointSize: Style.fontSizeS
        color: root.active ? Color.mOnPrimary : Color.mOnSurface
        elide: Text.ElideRight
      }
      NText {
        Layout.fillWidth: true
        text: root.subtitle
        pointSize: Style.fontSizeXS
        color: root.active ? Color.mOnPrimary : Color.mOnSurfaceVariant
        elide: Text.ElideRight
      }
    }
  }

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

  MouseArea {
    id: pointer
    anchors.fill: parent
    enabled: root.actionable && root.available
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: mouse => ControlCenterLayout.invoke(root.action, mouse.button === Qt.RightButton ? "right" : mouse.button === Qt.MiddleButton ? "middle" : "left")
  }
}
