import QtQuick
import QtQuick.Layouts
import "../../../Helpers/KdeConnect.js" as KdeConnect
import qs.Commons
import qs.Services.Networking
import qs.Widgets

// SMS thread list.
ColumnLayout {
  id: root
  required property var nav
  property string filter: ""

  readonly property var threads: {
    const query = filter.trim().toLowerCase();
    const list = KdeConnectService.conversations;
    if (!query)
      return list;
    return list.filter(t => KdeConnectService.threadTitle(t.addresses).toLowerCase().includes(query) || t.body.toLowerCase().includes(query) || t.addresses.some(a => a.includes(query)));
  }

  spacing: Style.marginM

  KdeConnectPageHeader {
    Layout.fillWidth: true
    nav: root.nav
    title: I18n.tr("kdeconnect.messages.title")
    subtitle: KdeConnectService.unreadCount > 0 ? I18n.tr("kdeconnect.messages.unread", {
                                                            count: KdeConnectService.unreadCount
                                                          }) : ""
    NIconButton {
      icon: "refresh"
      baseSize: Style.baseWidgetSize * 0.9
      onClicked: KdeConnectService.loadConversations()
    }
    NIconButton {
      icon: "message-plus"
      baseSize: Style.baseWidgetSize * 0.9
      colorBg: ShellColors.mPrimary
      colorFg: ShellColors.mOnPrimary
      onClicked: root.nav.push("compose")
    }
  }

  NTextInput {
    Layout.fillWidth: true
    inputIconName: "search"
    placeholderText: I18n.tr("kdeconnect.messages.search")
    onTextChanged: root.filter = text
  }

  Item {
    Layout.fillWidth: true
    Layout.fillHeight: true

    KdeConnectEmptyState {
      anchors.centerIn: parent
      width: parent.width
      visible: root.threads.length === 0
      icon: KdeConnectService.conversationsLoaded ? "messages" : "loader-2"
      title: !KdeConnectService.conversationsLoaded ? I18n.tr("kdeconnect.messages.loading") : root.filter ? I18n.tr("common.no-results") : I18n.tr("kdeconnect.messages.empty")
    }

    NListView {
      id: list
      anchors.fill: parent
      visible: root.threads.length > 0
      model: root.threads
      spacing: Style.marginXXS
      gradientColor: ShellColors.mSurface
      delegate: Rectangle {
        id: row
        required property var modelData
        readonly property bool unread: !modelData.sent && !modelData.read
        readonly property string name: KdeConnectService.threadTitle(modelData.addresses)
        width: list.width
        implicitHeight: Math.round(64 * Style.uiScaleRatio)
        radius: Style.radiusM
        color: hover.containsMouse ? Qt.alpha(ShellColors.mOnSurface, 0.06) : "transparent"

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: Style.marginS
          anchors.rightMargin: Style.marginS
          spacing: Style.marginM
          KdeConnectAvatar {
            name: row.name
            photo: row.modelData.addresses.length === 1 ? KdeConnectService.contactPhoto(row.modelData.addresses[0]) : ""
          }
          ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: Style.marginXXS
            RowLayout {
              Layout.fillWidth: true
              NText {
                Layout.fillWidth: true
                text: row.name
                pointSize: Style.fontSizeM
                font.weight: row.unread ? Style.fontWeightBold : Style.fontWeightMedium
                elide: Text.ElideRight
              }
              NText {
                text: KdeConnectService.formatStamp(row.modelData.date)
                pointSize: Style.fontSizeXS
                color: row.unread ? ShellColors.mPrimary : ShellColors.mOnSurfaceVariant
              }
            }
            RowLayout {
              Layout.fillWidth: true
              NText {
                Layout.fillWidth: true
                text: {
                  const body = row.modelData.body.replace(/\s+/g, " ") || (row.modelData.attachments.length ? I18n.tr("kdeconnect.messages.attachment") : "");
                  return row.modelData.sent ? I18n.tr("kdeconnect.messages.you", {
                                                        text: body
                                                      }) : body;
                }
                pointSize: Style.fontSizeS
                color: row.unread ? ShellColors.mOnSurface : ShellColors.mOnSurfaceVariant
                elide: Text.ElideRight
                maximumLineCount: 1
              }
              Rectangle {
                visible: row.unread
                implicitWidth: Math.round(8 * Style.uiScaleRatio)
                implicitHeight: implicitWidth
                radius: width / 2
                color: ShellColors.mPrimary
              }
            }
          }
        }

        MouseArea {
          id: hover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.nav.push("thread", {
                                     thread: row.modelData.thread,
                                     addresses: row.modelData.addresses
                                   })
        }
      }
    }
  }
}
