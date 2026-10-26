import QtQuick
import QtQuick.Layouts
import "../../../Helpers/KdeConnect.js" as KdeConnect
import qs.Commons
import qs.Services.Networking
import qs.Widgets

// Material phone pill: device icon, name, status and signal. Used as the
// KDE Connect panel header and as the control center card.
Rectangle {
  id: root
  property bool showChevron: KdeConnectService.pairedDevices.length > 1
  readonly property var device: KdeConnectService.activeDevice
  readonly property bool online: KdeConnectService.online
  signal clicked

  implicitHeight: Math.round(48 * Style.uiScaleRatio)
  radius: height / 2
  color: ShellColors.mSurfaceVariant

  NStyleCard {}

  NMaterialStateLayer {
    hovered: pointer.containsMouse
    pressed: pointer.pressed
    tint: ShellColors.mOnSurface
  }
  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: Style.marginL
    anchors.rightMargin: Style.marginM
    spacing: Style.marginS
    NIcon {
      icon: KdeConnect.deviceIcon(root.device)
      pointSize: Style.fontSizeXL
      color: root.online ? ShellColors.mPrimary : ShellColors.mOnSurfaceVariant
    }
    ColumnLayout {
      Layout.fillWidth: true
      Layout.minimumWidth: 0
      spacing: 0
      NText {
        Layout.fillWidth: true
        text: root.device ? root.device.name : I18n.tr("kdeconnect.title")
        pointSize: Style.fontSizeS
        font.weight: Style.fontWeightMedium
        elide: Text.ElideRight
      }
      NText {
        Layout.fillWidth: true
        visible: text !== ""
        text: KdeConnectService.statusText
        pointSize: Style.fontSizeXS
        color: ShellColors.mOnSurfaceVariant
        elide: Text.ElideRight
      }
    }
    NIcon {
      visible: root.online && !!root.device.network
      icon: KdeConnect.signalIcon(root.device?.network)
      color: ShellColors.mOnSurfaceVariant
    }
    NIcon {
      visible: root.showChevron
      icon: "chevron-down"
      color: ShellColors.mOnSurfaceVariant
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
