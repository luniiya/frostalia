import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../../Helpers/KdeConnect.js" as KdeConnect
import qs.Commons
import qs.Services.Networking
import qs.Widgets

// Device details, plugins, commands the phone can run here, and pairing.
ColumnLayout {
  id: root
  required property var nav
  readonly property var device: KdeConnectService.activeDevice
  property var commands: device ? device.runCommands.map(c => Object.assign({}, c)) : []
  property bool commandsDirty: false
  property bool confirmUnpair: false

  onDeviceChanged: {
    if (!commandsDirty)
      commands = device ? device.runCommands.map(c => Object.assign({}, c)) : [];
  }

  function editCommand(index, field, value) {
    const next = commands.slice();
    next[index] = Object.assign({}, next[index], {
                                  [field]: value
                                });
    commands = next;
    commandsDirty = true;
  }

  spacing: Style.marginM

  KdeConnectPageHeader {
    Layout.fillWidth: true
    nav: root.nav
    title: root.device ? root.device.name : I18n.tr("kdeconnect.device.title")
    subtitle: root.device ? (root.device.reachable ? root.device.providers.join(", ") : I18n.tr("kdeconnect.status.offline")) : ""
    NIconButton {
      icon: "refresh"
      baseSize: Style.baseWidgetSize * 0.9
      onClicked: KdeConnectService.refresh()
    }
  }

  NScrollView {
    Layout.fillWidth: true
    Layout.fillHeight: true
    gradientColor: ShellColors.mSurface
    horizontalPolicy: ScrollBar.AlwaysOff

    ColumnLayout {
      width: parent.width
      spacing: Style.marginL

      // This computer
      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginS
        NText {
          text: I18n.tr("kdeconnect.device.this-computer")
          pointSize: Style.fontSizeS
          font.weight: Style.fontWeightSemiBold
          color: ShellColors.mPrimary
        }
        NTextInput {
          id: nameInput
          Layout.fillWidth: true
          text: KdeConnectService.selfName
          placeholderText: I18n.tr("kdeconnect.device.computer-name")
          onEditingFinished: {
            if (text.trim() && text.trim() !== KdeConnectService.selfName)
              KdeConnectService.rename(text.trim());
          }
        }
      }

      // Pairing
      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginS
        NText {
          text: I18n.tr("kdeconnect.device.nearby")
          pointSize: Style.fontSizeS
          font.weight: Style.fontWeightSemiBold
          color: ShellColors.mPrimary
        }
        KdeConnectPairing {
          id: pairing
          Layout.fillWidth: true
        }
        NText {
          Layout.fillWidth: true
          visible: pairing.empty
          text: I18n.tr("kdeconnect.pairing.none-nearby")
          pointSize: Style.fontSizeXS
          color: ShellColors.mOnSurfaceVariant
          wrapMode: Text.Wrap
        }
      }

      // Plugins
      ColumnLayout {
        visible: !!root.device && root.device.paired
        Layout.fillWidth: true
        spacing: Style.marginXS
        NText {
          text: I18n.tr("kdeconnect.device.plugins")
          pointSize: Style.fontSizeS
          font.weight: Style.fontWeightSemiBold
          color: ShellColors.mPrimary
        }
        NText {
          Layout.fillWidth: true
          visible: !root.device?.reachable
          text: I18n.tr("kdeconnect.device.plugins-offline")
          pointSize: Style.fontSizeXS
          color: ShellColors.mOnSurfaceVariant
          wrapMode: Text.Wrap
        }
        Repeater {
          model: root.device?.reachable ? KdeConnect.pluginEntries(root.device) : []
          NToggle {
            required property var modelData
            Layout.fillWidth: true
            label: modelData.name
            checked: modelData.enabled
            onToggled: checked => KdeConnectService.setPluginEnabled(modelData.id, checked)
          }
        }
      }

      // Run commands
      ColumnLayout {
        visible: !!root.device && root.device.paired
        Layout.fillWidth: true
        spacing: Style.marginS
        NText {
          text: I18n.tr("kdeconnect.device.commands")
          pointSize: Style.fontSizeS
          font.weight: Style.fontWeightSemiBold
          color: ShellColors.mPrimary
        }
        NText {
          Layout.fillWidth: true
          text: I18n.tr("kdeconnect.device.commands-description")
          pointSize: Style.fontSizeXS
          color: ShellColors.mOnSurfaceVariant
          wrapMode: Text.Wrap
        }
        Repeater {
          model: root.commands
          RowLayout {
            id: commandRow
            required property var modelData
            required property int index
            Layout.fillWidth: true
            spacing: Style.marginS
            NTextInput {
              Layout.preferredWidth: Math.round(110 * Style.uiScaleRatio)
              text: commandRow.modelData.name
              placeholderText: I18n.tr("kdeconnect.device.command-name")
              showClearButton: false
              onEditingFinished: root.editCommand(commandRow.index, "name", text)
            }
            NTextInput {
              Layout.fillWidth: true
              text: commandRow.modelData.command
              placeholderText: I18n.tr("kdeconnect.device.command-line")
              fontFamily: Style.fontFixed
              showClearButton: false
              onEditingFinished: root.editCommand(commandRow.index, "command", text)
            }
            NIconButton {
              icon: "trash"
              baseSize: Style.baseWidgetSize * 0.8
              onClicked: {
                root.commands = root.commands.filter((c, i) => i !== commandRow.index);
                root.commandsDirty = true;
              }
            }
          }
        }
        RowLayout {
          Layout.fillWidth: true
          spacing: Style.marginS
          NButton {
            text: I18n.tr("common.add")
            icon: "plus"
            outlined: true
            onClicked: {
              root.commands = root.commands.concat([
                                                     {
                                                       id: "",
                                                       name: "",
                                                       command: ""
                                                     }
                                                   ]);
              root.commandsDirty = true;
            }
          }
          Item {
            Layout.fillWidth: true
          }
          NButton {
            visible: root.commandsDirty
            text: I18n.tr("common.save")
            icon: "check"
            onClicked: {
              KdeConnectService.setRunCommands(root.commands);
              root.commandsDirty = false;
            }
          }
        }
      }

      // Details and unpair
      ColumnLayout {
        visible: !!root.device && root.device.paired
        Layout.fillWidth: true
        spacing: Style.marginXS
        NText {
          text: I18n.tr("kdeconnect.device.details")
          pointSize: Style.fontSizeS
          font.weight: Style.fontWeightSemiBold
          color: ShellColors.mPrimary
        }
        Repeater {
          model: root.device ? [[I18n.tr("kdeconnect.device.id"), root.device.id], [I18n.tr("kdeconnect.device.addresses"), root.device.addresses.join(", ")], [I18n.tr("kdeconnect.device.verification-key"), root.device.verificationKey]].filter(r => r[1]) : []
          ColumnLayout {
            required property var modelData
            Layout.fillWidth: true
            spacing: 0
            NText {
              text: modelData[0]
              pointSize: Style.fontSizeXS
              color: ShellColors.mOnSurfaceVariant
            }
            NText {
              Layout.fillWidth: true
              text: modelData[1]
              pointSize: Style.fontSizeXS
              font.family: Style.fontFixed
              wrapMode: Text.WrapAnywhere
            }
          }
        }
        NButton {
          Layout.topMargin: Style.marginS
          Layout.fillWidth: true
          text: root.confirmUnpair ? I18n.tr("kdeconnect.device.unpair-confirm", {
                                               device: root.device?.name || ""
                                             }) : I18n.tr("common.unpair")
          icon: "unlink"
          backgroundColor: ShellColors.mError
          textColor: ShellColors.mOnError
          onClicked: {
            if (!root.confirmUnpair) {
              root.confirmUnpair = true;
              return;
            }
            KdeConnectService.unpair(root.device.id);
            root.confirmUnpair = false;
            root.nav.reset();
          }
        }
      }
    }
  }
}
