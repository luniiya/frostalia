import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../../Helpers/KdeConnect.js" as KdeConnect
import qs.Commons
import qs.Services.Networking
import qs.Widgets

// Browse the phone's storage and send things to it.
ColumnLayout {
  id: root
  required property var nav
  readonly property var device: KdeConnectService.activeDevice
  readonly property var sftp: device?.sftp || null
  readonly property bool canBrowse: KdeConnect.hasPlugin(device, "sftp")
  readonly property bool canShare: KdeConnect.hasPlugin(device, "share")

  spacing: Style.marginM

  KdeConnectPageHeader {
    Layout.fillWidth: true
    nav: root.nav
    title: I18n.tr("kdeconnect.files.title")
    NIconButton {
      visible: !!root.sftp && root.sftp.mounted
      icon: "plug-x"
      baseSize: Style.baseWidgetSize * 0.9
      onClicked: KdeConnectService.unmount()
    }
  }

  NScrollView {
    Layout.fillWidth: true
    Layout.fillHeight: true
    gradientColor: ShellColors.mSurface
    horizontalPolicy: ScrollBar.AlwaysOff

    ColumnLayout {
      width: parent.width
      spacing: Style.marginM

      // Phone storage
      NBox {
        visible: root.canBrowse
        Layout.fillWidth: true
        implicitHeight: storage.implicitHeight + Style.margin2M
        ColumnLayout {
          id: storage
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.margins: Style.marginM
          spacing: Style.marginS

          RowLayout {
            Layout.fillWidth: true
            NIcon {
              icon: root.sftp?.mounted ? "folder-open" : "folder"
              pointSize: Style.fontSizeXL
              color: ShellColors.mPrimary
            }
            ColumnLayout {
              Layout.fillWidth: true
              spacing: 0
              NText {
                text: I18n.tr("kdeconnect.files.phone-storage")
                pointSize: Style.fontSizeM
                font.weight: Style.fontWeightSemiBold
              }
              NText {
                Layout.fillWidth: true
                text: root.sftp?.mounted ? root.sftp.mountPoint : I18n.tr("kdeconnect.files.not-mounted")
                pointSize: Style.fontSizeXS
                color: ShellColors.mOnSurfaceVariant
                elide: Text.ElideMiddle
              }
            }
            NButton {
              text: root.sftp?.mounted ? I18n.tr("kdeconnect.files.open") : I18n.tr("kdeconnect.files.mount")
              icon: root.sftp?.mounted ? "external-link" : "plug"
              onClicked: root.sftp?.mounted ? KdeConnectService.browse() : KdeConnectService.mount()
            }
          }

          NText {
            Layout.fillWidth: true
            visible: !!root.sftp && root.sftp.error !== "" && !root.sftp.mounted
            text: root.sftp?.error || ""
            pointSize: Style.fontSizeXS
            color: ShellColors.mError
            wrapMode: Text.Wrap
          }

          Repeater {
            model: root.sftp?.mounted ? root.sftp.directories : []
            Rectangle {
              id: dir
              required property var modelData
              Layout.fillWidth: true
              implicitHeight: Math.round(40 * Style.uiScaleRatio)
              radius: Style.radiusS
              color: dirPointer.containsMouse ? Qt.alpha(ShellColors.mOnSurface, 0.06) : "transparent"
              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Style.marginS
                anchors.rightMargin: Style.marginS
                spacing: Style.marginM
                NIcon {
                  icon: "folder"
                  color: ShellColors.mOnSurfaceVariant
                }
                NText {
                  Layout.fillWidth: true
                  text: dir.modelData.name || dir.modelData.path
                  pointSize: Style.fontSizeS
                  elide: Text.ElideRight
                }
                NIcon {
                  icon: "chevron-right"
                  color: ShellColors.mOnSurfaceVariant
                }
              }
              MouseArea {
                id: dirPointer
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: KdeConnectService.openPath(dir.modelData.path)
              }
            }
          }
        }
      }

      // Send to phone
      NBox {
        visible: root.canShare
        Layout.fillWidth: true
        implicitHeight: send.implicitHeight + Style.margin2M
        ColumnLayout {
          id: send
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.margins: Style.marginM
          spacing: Style.marginS

          NText {
            text: I18n.tr("kdeconnect.files.send-title", {
                            device: root.device?.name || ""
                          })
            pointSize: Style.fontSizeM
            font.weight: Style.fontWeightSemiBold
          }
          NText {
            Layout.fillWidth: true
            text: I18n.tr("kdeconnect.files.drop-hint")
            pointSize: Style.fontSizeXS
            color: ShellColors.mOnSurfaceVariant
            wrapMode: Text.Wrap
          }
          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS
            NButton {
              Layout.fillWidth: true
              text: I18n.tr("kdeconnect.send-files")
              icon: "file-upload"
              onClicked: root.nav.pickFiles()
            }
            NButton {
              Layout.fillWidth: true
              visible: KdeConnect.hasPlugin(root.device, "clipboard")
              text: I18n.tr("kdeconnect.actions.clipboard")
              icon: "clipboard"
              outlined: true
              onClicked: KdeConnectService.sendClipboard()
            }
          }
          KdeConnectComposer {
            Layout.fillWidth: true
            placeholder: I18n.tr("kdeconnect.files.send-text")
            onSend: text => KdeConnectService.shareText(text)
          }
        }
      }
    }
  }
}
