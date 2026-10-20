import QtQuick
import QtQuick.Layouts
import "../../../Helpers/KdeConnect.js" as KdeConnect
import qs.Commons
import qs.Services.Networking
import qs.Widgets

// Compact phone row for the Caelestia control center; opens the KDE Connect
// panel.
NBox {
  id: root
  readonly property var device: KdeConnectService.activeDevice
  readonly property bool online: KdeConnectService.online
  signal clicked

  color: pointer.containsMouse ? ShellColors.mHover : ShellColors.mSurfaceVariant

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: Style.marginM
    anchors.rightMargin: Style.marginM
    spacing: Style.marginM
    Rectangle {
      Layout.preferredWidth: Math.round(40 * Style.uiScaleRatio)
      Layout.preferredHeight: Layout.preferredWidth
      radius: Style.radiusM
      color: root.online ? ShellColors.mPrimary : ShellColors.mSurface
      NIcon {
        anchors.centerIn: parent
        icon: KdeConnect.deviceIcon(root.device)
        pointSize: Style.fontSizeXL
        color: root.online ? ShellColors.mOnPrimary : ShellColors.mOnSurfaceVariant
      }
    }
    ColumnLayout {
      Layout.fillWidth: true
      Layout.minimumWidth: 0
      spacing: 0
      NText {
        Layout.fillWidth: true
        text: root.device ? root.device.name : I18n.tr("kdeconnect.title")
        pointSize: Style.fontSizeM
        font.weight: Style.fontWeightBold
        color: pointer.containsMouse ? ShellColors.mOnHover : ShellColors.mOnSurface
        elide: Text.ElideRight
      }
      NText {
        Layout.fillWidth: true
        visible: text !== ""
        text: KdeConnectService.statusText
        pointSize: Style.fontSizeXS
        color: pointer.containsMouse ? ShellColors.mOnHover : ShellColors.mOnSurfaceVariant
        elide: Text.ElideRight
      }
    }
    NIcon {
      visible: root.online && !!root.device.network
      icon: KdeConnect.signalIcon(root.device?.network)
      color: pointer.containsMouse ? ShellColors.mOnHover : ShellColors.mOnSurfaceVariant
    }
    NIcon {
      icon: "chevron-right"
      color: pointer.containsMouse ? ShellColors.mOnHover : ShellColors.mOnSurfaceVariant
    }
  }
  MouseArea {
    id: pointer
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
