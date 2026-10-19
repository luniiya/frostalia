import QtQuick
import QtQuick.Layouts
import "../../../Helpers/KdeConnect.js" as KdeConnect
import qs.Commons
import qs.Services.Networking
import qs.Widgets

// Caelestia home: stacked NBox cards with a device header, labelled action
// buttons and a feature list (no quick settings tiles).
ColumnLayout {
  id: root
  required property var nav
  readonly property var device: KdeConnectService.activeDevice
  readonly property bool online: KdeConnectService.online

  spacing: Style.marginL

  // Device header
  NBox {
    Layout.fillWidth: true
    implicitHeight: header.implicitHeight + Style.margin2M
    RowLayout {
      id: header
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.margins: Style.marginM
      spacing: Style.marginM

      Rectangle {
        Layout.preferredWidth: Math.round(48 * Style.uiScaleRatio)
        Layout.preferredHeight: Layout.preferredWidth
        radius: Style.radiusM
        color: root.online ? Color.mPrimary : Color.mSurface
        NIcon {
          anchors.centerIn: parent
          icon: KdeConnect.deviceIcon(root.device)
          pointSize: Style.fontSizeXXL
          color: root.online ? Color.mOnPrimary : Color.mOnSurfaceVariant
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        spacing: Style.marginXXS
        NText {
          Layout.fillWidth: true
          text: root.device ? root.device.name : I18n.tr("kdeconnect.title")
          pointSize: Style.fontSizeL
          font.weight: Style.fontWeightBold
          elide: Text.ElideRight
        }
        RowLayout {
          spacing: Style.marginXS
          NIcon {
            visible: root.online && !!root.device.network
            icon: KdeConnect.signalIcon(root.device?.network)
            pointSize: Style.fontSizeS
            color: Color.mOnSurfaceVariant
          }
          NText {
            text: root.nav.statusText
            pointSize: Style.fontSizeS
            color: Color.mOnSurfaceVariant
          }
        }
        // Battery bar
        Rectangle {
          visible: root.online && !!root.device.battery && root.device.battery.charge >= 0
          Layout.fillWidth: true
          Layout.topMargin: Style.marginXXS
          implicitHeight: Math.round(4 * Style.uiScaleRatio)
          radius: height / 2
          color: Qt.alpha(Color.mOnSurface, 0.12)
          Rectangle {
            width: parent.width * Math.max(0, Math.min(100, root.device?.battery?.charge || 0)) / 100
            height: parent.height
            radius: height / 2
            color: (root.device?.battery?.charge || 0) <= 15 && !root.device?.battery?.charging ? Color.mError : Color.mPrimary
          }
        }
      }

      NIconButton {
        visible: KdeConnectService.pairedDevices.length > 1
        icon: "arrows-exchange"
        baseSize: Style.baseWidgetSize * 0.85
        onClicked: root.nav.openDeviceMenu(this)
      }
      NIconButton {
        icon: "settings"
        baseSize: Style.baseWidgetSize * 0.85
        onClicked: root.nav.push("device")
      }
    }
  }

  // Not connected
  NBox {
    visible: !root.online
    Layout.fillWidth: true
    implicitHeight: setup.implicitHeight + Style.margin2L
    KdeConnectSetupState {
      id: setup
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: Style.marginL
      nav: root.nav
    }
  }

  // Actions: icon buttons with labels underneath
  NBox {
    visible: root.online && root.nav.actions.length > 0
    Layout.fillWidth: true
    implicitHeight: actionRow.implicitHeight + Style.margin2M
    RowLayout {
      id: actionRow
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.margins: Style.marginM
      spacing: Style.marginS
      Repeater {
        model: root.nav.actions
        ColumnLayout {
          required property var modelData
          Layout.fillWidth: true
          spacing: Style.marginXS
          NIconButton {
            Layout.alignment: Qt.AlignHCenter
            icon: modelData.icon
            baseSize: Style.baseWidgetSize * 1.15
            onClicked: root.nav.runAction(modelData.id)
          }
          NText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: root.nav.actionTitle(modelData.id)
            pointSize: Style.fontSizeXS
            color: Color.mOnSurfaceVariant
            elide: Text.ElideRight
          }
        }
      }
    }
  }

  // Now playing
  NBox {
    visible: root.online && !!root.device?.media && root.device.media.title !== ""
    Layout.fillWidth: true
    implicitHeight: media.implicitHeight + Style.margin2M
    KdeConnectMediaControls {
      id: media
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.margins: Style.marginM
    }
  }

  // Latest conversations
  NBox {
    visible: root.online && KdeConnect.hasPlugin(root.device, "sms") && KdeConnectService.conversations.length > 0
    Layout.fillWidth: true
    implicitHeight: recent.implicitHeight + Style.margin2M
    KdeConnectRecentThreads {
      id: recent
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: Style.marginM
      nav: root.nav
    }
  }

  // Features
  NBox {
    visible: root.online && root.nav.features.length > 0
    Layout.fillWidth: true
    implicitHeight: featureList.implicitHeight + Style.margin2S
    ColumnLayout {
      id: featureList
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: Style.marginS
      spacing: 0
      Repeater {
        model: root.nav.features
        Rectangle {
          id: feature
          required property var modelData
          readonly property int badge: root.nav.featureBadge(modelData.id)
          Layout.fillWidth: true
          implicitHeight: Math.round(50 * Style.uiScaleRatio)
          radius: Style.radiusS
          color: featurePointer.containsMouse ? Color.mHover : "transparent"
          readonly property color fg: featurePointer.containsMouse ? Color.mOnHover : Color.mOnSurface
          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Style.marginM
            anchors.rightMargin: Style.marginM
            spacing: Style.marginM
            NIcon {
              icon: feature.modelData.icon
              pointSize: Style.fontSizeL
              color: featurePointer.containsMouse ? feature.fg : Color.mPrimary
            }
            ColumnLayout {
              Layout.fillWidth: true
              Layout.minimumWidth: 0
              spacing: 0
              NText {
                Layout.fillWidth: true
                text: root.nav.featureTitle(feature.modelData.id)
                pointSize: Style.fontSizeM
                color: feature.fg
                elide: Text.ElideRight
              }
              NText {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.nav.featureSubtitle(feature.modelData.id)
                pointSize: Style.fontSizeXS
                color: featurePointer.containsMouse ? feature.fg : Color.mOnSurfaceVariant
                elide: Text.ElideRight
              }
            }
            Rectangle {
              visible: feature.badge > 0
              implicitHeight: Math.round(20 * Style.uiScaleRatio)
              implicitWidth: Math.max(implicitHeight, badgeLabel.implicitWidth + Style.marginM)
              radius: height / 2
              color: Color.mPrimary
              NText {
                id: badgeLabel
                anchors.centerIn: parent
                text: feature.badge > 99 ? "99+" : String(feature.badge)
                pointSize: Style.fontSizeXXS
                font.weight: Style.fontWeightBold
                color: Color.mOnPrimary
              }
            }
            NIcon {
              icon: "chevron-right"
              color: featurePointer.containsMouse ? feature.fg : Color.mOnSurfaceVariant
            }
          }
          MouseArea {
            id: featurePointer
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.nav.push(feature.modelData.id)
          }
        }
      }
    }
  }
}
