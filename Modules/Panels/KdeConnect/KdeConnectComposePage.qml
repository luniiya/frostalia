import QtQuick
import QtQuick.Layouts
import "../../../Helpers/KdeConnect.js" as KdeConnect
import qs.Commons
import qs.Services.Networking
import qs.Services.UI
import qs.Widgets

// New SMS: pick a contact or type a number, then write the message.
ColumnLayout {
  id: root
  required property var nav
  property string recipient: ""

  readonly property var suggestions: {
    const query = recipient.trim().toLowerCase();
    if (!query)
      return KdeConnectService.contacts.slice(0, 30);
    const digits = KdeConnect.normalizeNumber(query);
    return KdeConnectService.contacts.filter(c => c.name.toLowerCase().includes(query) || (digits && c.numbers.some(n => KdeConnect.normalizeNumber(n).includes(digits)))).slice(0, 30);
  }
  // An existing thread with this number opens instead of a new one.
  readonly property var existingThread: KdeConnectService.conversations.find(t => t.addresses.length === 1 && KdeConnect.normalizeNumber(t.addresses[0]) === KdeConnect.normalizeNumber(recipient)) || null

  function send(text) {
    if (root.existingThread) {
      root.nav.pop();
      root.nav.push("thread", {
                      thread: root.existingThread.thread,
                      addresses: root.existingThread.addresses
                    });
      KdeConnectService.reply(text);
      return;
    }
    if (KdeConnectService.sendNewMessage([root.recipient], text)) {
      ToastService.showNotice(I18n.tr("kdeconnect.messages.sent"), KdeConnectService.contactName(root.recipient), "send");
      root.nav.pop();
    }
  }

  spacing: Style.marginM

  Component.onCompleted: {
    if (KdeConnectService.contacts.length === 0)
      KdeConnectService.syncContacts();
    to.inputItem.forceActiveFocus();
  }

  KdeConnectPageHeader {
    Layout.fillWidth: true
    nav: root.nav
    title: I18n.tr("kdeconnect.messages.new")
  }

  NTextInput {
    id: to
    Layout.fillWidth: true
    inputIconName: "user"
    placeholderText: I18n.tr("kdeconnect.messages.recipient")
    text: root.recipient
    onTextChanged: root.recipient = text
    onAccepted: composer.focusField()
  }

  Item {
    Layout.fillWidth: true
    Layout.fillHeight: true

    KdeConnectEmptyState {
      anchors.centerIn: parent
      width: parent.width
      visible: root.suggestions.length === 0
      icon: "address-book"
      title: KdeConnectService.contacts.length ? I18n.tr("common.no-results") : I18n.tr("kdeconnect.messages.no-contacts")
      description: KdeConnectService.contacts.length ? "" : I18n.tr("kdeconnect.messages.no-contacts-description")
    }

    NListView {
      id: list
      anchors.fill: parent
      visible: root.suggestions.length > 0
      model: root.suggestions
      gradientColor: Color.mSurface
      delegate: Rectangle {
        id: row
        required property var modelData
        width: list.width
        implicitHeight: Math.round(52 * Style.uiScaleRatio)
        radius: Style.radiusM
        color: pointer.containsMouse ? Qt.alpha(Color.mOnSurface, 0.06) : "transparent"
        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: Style.marginS
          anchors.rightMargin: Style.marginS
          spacing: Style.marginM
          KdeConnectAvatar {
            size: Math.round(34 * Style.uiScaleRatio)
            name: row.modelData.name
            photo: row.modelData.photo
          }
          ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            NText {
              Layout.fillWidth: true
              text: row.modelData.name
              pointSize: Style.fontSizeM
              elide: Text.ElideRight
            }
            NText {
              Layout.fillWidth: true
              text: row.modelData.numbers.join(", ")
              pointSize: Style.fontSizeXS
              color: Color.mOnSurfaceVariant
              elide: Text.ElideRight
            }
          }
        }
        MouseArea {
          id: pointer
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            to.text = row.modelData.numbers[0];
            composer.focusField();
          }
        }
      }
    }
  }

  KdeConnectComposer {
    id: composer
    Layout.fillWidth: true
    canSend: KdeConnectService.online && root.recipient.trim() !== ""
    onSend: text => root.send(text)
  }
}
