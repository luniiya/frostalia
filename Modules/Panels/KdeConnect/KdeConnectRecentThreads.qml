import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services.Networking
import qs.Widgets

// The three latest SMS threads, for the home pages.
ColumnLayout {
  id: root
  required property var nav
  property int count: 3

  spacing: 0

  RowLayout {
    Layout.fillWidth: true
    Layout.leftMargin: Style.marginS
    NText {
      Layout.fillWidth: true
      text: I18n.tr("kdeconnect.messages.recent")
      pointSize: Style.fontSizeS
      font.weight: Style.fontWeightSemiBold
    }
    NButton {
      text: I18n.tr("kdeconnect.messages.see-all")
      outlined: true
      fontSize: Style.fontSizeXS
      onClicked: root.nav.push("messages")
    }
  }

  Repeater {
    model: KdeConnectService.conversations.slice(0, root.count)
    Rectangle {
      id: row
      required property var modelData
      readonly property bool unread: !modelData.sent && !modelData.read
      readonly property string name: KdeConnectService.threadTitle(modelData.addresses)
      Layout.fillWidth: true
      Layout.topMargin: Style.marginXS
      implicitHeight: Math.round(52 * Style.uiScaleRatio)
      radius: Style.radiusS
      color: pointer.containsMouse ? Qt.alpha(Color.mOnSurface, 0.06) : "transparent"
      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Style.marginS
        anchors.rightMargin: Style.marginS
        spacing: Style.marginM
        KdeConnectAvatar {
          size: Math.round(36 * Style.uiScaleRatio)
          name: row.name
          photo: row.modelData.addresses.length === 1 ? KdeConnectService.contactPhoto(row.modelData.addresses[0]) : ""
        }
        ColumnLayout {
          Layout.fillWidth: true
          Layout.minimumWidth: 0
          spacing: 0
          NText {
            Layout.fillWidth: true
            text: row.name
            pointSize: Style.fontSizeS
            font.weight: row.unread ? Style.fontWeightBold : Style.fontWeightMedium
            elide: Text.ElideRight
          }
          NText {
            Layout.fillWidth: true
            text: row.modelData.body.replace(/\s+/g, " ")
            pointSize: Style.fontSizeXS
            color: row.unread ? Color.mOnSurface : Color.mOnSurfaceVariant
            elide: Text.ElideRight
          }
        }
        NText {
          text: KdeConnectService.formatStamp(row.modelData.date)
          pointSize: Style.fontSizeXXS
          color: row.unread ? Color.mPrimary : Color.mOnSurfaceVariant
        }
      }
      MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.nav.openThread(row.modelData)
      }
    }
  }
}
