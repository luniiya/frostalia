import QtQuick
import QtQuick.Layouts
import "../../../Helpers/ControlCenterLayout.js" as ControlCenterLayout
import "../../../Helpers/KdeConnect.js" as KdeConnect
import qs.Commons
import qs.Modules.Panels.ControlCenter
import qs.Services.Networking
import qs.Widgets

// Material home: control center pieces (pill header, tonal cards, quick
// settings tiles) arranged as a phone dashboard.
ColumnLayout {
  id: root
  required property var nav
  readonly property var device: KdeConnectService.activeDevice
  readonly property bool online: KdeConnectService.online
  readonly property real tileGap: Style.marginXS

  spacing: Style.marginS

  // Header pills, like MaterialControlHeader.
  RowLayout {
    Layout.fillWidth: true
    Layout.preferredHeight: Math.round(48 * Style.uiScaleRatio)
    spacing: Style.marginS

    KdeConnectPill {
      id: devicePill
      Layout.fillWidth: true
      Layout.fillHeight: true
      onClicked: KdeConnectService.pairedDevices.length > 1 ? root.nav.openDeviceMenu(devicePill) : root.nav.push("device")
    }

    NPill {
      Layout.fillHeight: true
      NIconButton {
        icon: "settings"
        baseSize: Style.baseWidgetSize
        onClicked: root.nav.push("device")
      }
      NIconButton {
        icon: "close"
        baseSize: Style.baseWidgetSize
        onClicked: root.nav.close()
      }
    }
  }

  // Not connected
  Rectangle {
    visible: !root.online
    Layout.fillWidth: true
    implicitHeight: setup.implicitHeight + Style.margin2L
    radius: Style.radiusM
    color: Color.mSurfaceVariant
    KdeConnectSetupState {
      id: setup
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: Style.marginL
      nav: root.nav
    }
  }

  // Quick actions and feature tiles, laid out like the shortcuts card.
  Rectangle {
    visible: root.online && (root.nav.actions.length + root.nav.features.length) > 0
    Layout.fillWidth: true
    implicitHeight: tiles.implicitHeight + Style.margin2S
    radius: Style.radiusM
    color: Color.mSurfaceVariant
    ColumnLayout {
      id: tiles
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: Style.marginS
      spacing: root.tileGap

      RowLayout {
        visible: root.nav.actions.length > 0
        Layout.fillWidth: true
        spacing: root.tileGap
        Repeater {
          model: root.nav.actions
          MaterialTile {
            required property var modelData
            Layout.preferredWidth: ControlCenterLayout.equalWidth(tiles.width, root.tileGap, root.nav.actions.length)
            icon: modelData.icon
            title: root.nav.actionTitle(modelData.id)
            Accessible.name: title
            onClicked: root.nav.runAction(modelData.id)
          }
        }
      }

      GridLayout {
        visible: root.nav.features.length > 0
        Layout.fillWidth: true
        columns: 2
        columnSpacing: root.tileGap
        rowSpacing: root.tileGap
        Repeater {
          model: root.nav.features
          MaterialTile {
            required property var modelData
            Layout.preferredWidth: ControlCenterLayout.equalWidth(tiles.width, root.tileGap, 2)
            wide: true
            icon: modelData.icon
            title: root.nav.featureTitle(modelData.id)
            subtitle: root.nav.featureSubtitle(modelData.id)
            active: modelData.id === "media" && !!root.device?.media?.playing
            onClicked: root.nav.push(modelData.id)
          }
        }
      }
    }
  }

  // Now playing on the phone
  Rectangle {
    visible: root.online && !!root.device?.media && root.device.media.title !== ""
    Layout.fillWidth: true
    implicitHeight: media.implicitHeight + Style.margin2M
    radius: Style.radiusM
    color: Color.mSurfaceVariant
    KdeConnectMediaControls {
      id: media
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: Style.marginM
    }
  }

  // Latest conversations
  Rectangle {
    visible: root.online && KdeConnect.hasPlugin(root.device, "sms") && KdeConnectService.conversations.length > 0
    Layout.fillWidth: true
    implicitHeight: recent.implicitHeight + Style.margin2S
    radius: Style.radiusM
    color: Color.mSurfaceVariant
    KdeConnectRecentThreads {
      id: recent
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: Style.marginS
      nav: root.nav
    }
  }
}
