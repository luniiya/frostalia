import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../../Helpers/KdeConnect.js" as KdeConnect
import qs.Commons
import qs.Services.Networking
import qs.Widgets

// One SMS conversation: grouped bubbles, newest at the bottom, and a reply box.
ColumnLayout {
  id: root
  required property var nav
  required property int thread
  property var addresses: []

  readonly property string title: KdeConnectService.threadTitle(addresses)
  // Newest first: the list grows upwards, so older pages load at the top.
  readonly property var rows: KdeConnect.bubbles(KdeConnectService.threadMessages).reverse()
  readonly property real bubbleRadius: Math.round(18 * Style.uiScaleRatio)
  readonly property real joinedRadius: Math.round(5 * Style.uiScaleRatio)

  spacing: Style.marginM

  Component.onCompleted: {
    KdeConnectService.openConversation(thread);
    composer.focusField();
  }

  KdeConnectPageHeader {
    Layout.fillWidth: true
    nav: root.nav
    title: root.title
    subtitle: root.addresses.length === 1 && root.title !== root.addresses[0] ? root.addresses[0] : ""
  }

  Item {
    Layout.fillWidth: true
    Layout.fillHeight: true

    NBusyIndicator {
      anchors.centerIn: parent
      visible: root.rows.length === 0 && KdeConnectService.threadLoading
      running: visible
    }

    ListView {
      id: list
      anchors.fill: parent
      clip: true
      model: root.rows
      spacing: Style.marginXXS
      boundsBehavior: Flickable.StopAtBounds
      verticalLayoutDirection: ListView.BottomToTop
      ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
      }
      onAtYBeginningChanged: {
        if (atYBeginning && count > 0)
          KdeConnectService.loadOlderMessages();
      }

      footer: Item {
        width: list.width
        height: KdeConnectService.threadLoading && root.rows.length > 0 ? Math.round(32 * Style.uiScaleRatio) : 0
        NBusyIndicator {
          anchors.centerIn: parent
          visible: parent.height > 0
          running: visible
          size: Math.round(20 * Style.uiScaleRatio)
        }
      }

      delegate: Item {
        id: row
        required property var modelData
        readonly property var message: modelData.message
        readonly property bool sent: message.sent
        readonly property var images: KdeConnect.attachmentImages(message)
        readonly property real maxBubble: list.width * 0.78
        width: list.width
        implicitHeight: column.implicitHeight + (modelData.last ? Style.marginS : 0)

        ColumnLayout {
          id: column
          width: parent.width
          spacing: Style.marginXXS

          NText {
            Layout.fillWidth: true
            Layout.topMargin: Style.marginM
            Layout.bottomMargin: Style.marginS
            visible: row.modelData.daySeparator
            horizontalAlignment: Text.AlignHCenter
            text: KdeConnectService.formatDay(row.message.date)
            pointSize: Style.fontSizeXS
            color: Color.mOnSurfaceVariant
          }

          Rectangle {
            id: bubble
            Layout.alignment: row.sent ? Qt.AlignRight : Qt.AlignLeft
            Layout.preferredWidth: Math.min(row.maxBubble, Math.max(body.visible ? body.naturalWidth + 2 : 0, imageColumn.visible ? imageColumn.implicitWidth : 0) + Style.margin2M)
            Layout.preferredHeight: content.implicitHeight + Style.margin2S
            color: row.sent ? Color.mPrimary : Color.mSurfaceVariant
            opacity: row.message.pending ? 0.6 : 1
            topLeftRadius: !row.sent && !row.modelData.first ? root.joinedRadius : root.bubbleRadius
            bottomLeftRadius: !row.sent && !row.modelData.last ? root.joinedRadius : root.bubbleRadius
            topRightRadius: row.sent && !row.modelData.first ? root.joinedRadius : root.bubbleRadius
            bottomRightRadius: row.sent && !row.modelData.last ? root.joinedRadius : root.bubbleRadius

            ColumnLayout {
              id: content
              anchors.fill: parent
              anchors.leftMargin: Style.marginM
              anchors.rightMargin: Style.marginM
              anchors.topMargin: Style.marginS
              anchors.bottomMargin: Style.marginS
              spacing: Style.marginXS

              ColumnLayout {
                id: imageColumn
                visible: row.images.length > 0
                spacing: Style.marginXS
                Repeater {
                  model: row.images
                  Image {
                    required property var modelData
                    Layout.preferredWidth: Math.min(row.maxBubble - Style.margin2M, Math.round(200 * Style.uiScaleRatio))
                    Layout.preferredHeight: sourceSize.width > 0 ? Layout.preferredWidth * sourceSize.height / sourceSize.width : Layout.preferredWidth
                    source: modelData.thumbnail
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                  }
                }
              }

              TextEdit {
                id: body
                Layout.fillWidth: true
                visible: text !== ""
                text: row.message.body
                readOnly: true
                selectByMouse: true
                wrapMode: TextEdit.Wrap
                textFormat: TextEdit.PlainText
                color: row.sent ? Color.mOnPrimary : Color.mOnSurface
                selectionColor: row.sent ? Color.mOnPrimary : Color.mPrimary
                selectedTextColor: row.sent ? Color.mPrimary : Color.mOnPrimary
                font.family: Style.fontDefault
                font.pointSize: Style.fontSizeM * Style.uiScaleRatio
                // Unwrapped width, so short messages get narrow bubbles.
                readonly property real naturalWidth: metrics.advanceWidth
                TextMetrics {
                  id: metrics
                  font: body.font
                  text: row.message.body.split("\n").reduce((a, b) => a.length > b.length ? a : b, "")
                }
              }
            }
          }

          NText {
            Layout.alignment: row.sent ? Qt.AlignRight : Qt.AlignLeft
            Layout.leftMargin: Style.marginS
            Layout.rightMargin: Style.marginS
            visible: row.modelData.last
            text: row.message.pending ? I18n.tr("kdeconnect.messages.sending") : KdeConnectService.formatStamp(row.message.date)
            pointSize: Style.fontSizeXXS
            color: Color.mOnSurfaceVariant
          }
        }
      }
    }
  }

  KdeConnectComposer {
    id: composer
    Layout.fillWidth: true
    canSend: KdeConnectService.online
    onSend: text => KdeConnectService.reply(text)
  }
}
