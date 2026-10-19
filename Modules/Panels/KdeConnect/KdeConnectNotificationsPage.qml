import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services.Networking
import qs.Widgets

// Notifications on the phone: read, dismiss and reply.
ColumnLayout {
  id: root
  required property var nav
  readonly property var notifications: KdeConnectService.activeDevice?.notifications || []
  property string replying: ""

  spacing: Style.marginM

  KdeConnectPageHeader {
    Layout.fillWidth: true
    nav: root.nav
    title: I18n.tr("kdeconnect.notifications.title")
    subtitle: root.notifications.length ? I18n.tr("kdeconnect.notifications.count", {
                                                    count: root.notifications.length
                                                  }) : ""
    NIconButton {
      visible: root.notifications.some(n => n.dismissable)
      icon: "trash"
      baseSize: Style.baseWidgetSize * 0.9
      onClicked: root.notifications.filter(n => n.dismissable).forEach(n => KdeConnectService.dismissNotification(n.id))
    }
  }

  Item {
    Layout.fillWidth: true
    Layout.fillHeight: true

    KdeConnectEmptyState {
      anchors.centerIn: parent
      width: parent.width
      visible: root.notifications.length === 0
      icon: "bell-off"
      title: I18n.tr("kdeconnect.notifications.empty")
    }

    NListView {
      id: list
      anchors.fill: parent
      visible: root.notifications.length > 0
      model: root.notifications
      spacing: Style.marginS
      gradientColor: Color.mSurface
      delegate: NBox {
        id: card
        required property var modelData
        readonly property bool replyOpen: root.replying === modelData.id
        width: list.width
        implicitHeight: body.implicitHeight + Style.margin2M

        ColumnLayout {
          id: body
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.margins: Style.marginM
          spacing: Style.marginS

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginM
            NImageRounded {
              Layout.preferredWidth: Math.round(36 * Style.uiScaleRatio)
              Layout.preferredHeight: Layout.preferredWidth
              Layout.alignment: Qt.AlignTop
              radius: Style.radiusS
              imagePath: card.modelData.icon
              fallbackIcon: "bell"
              fallbackIconSize: Style.fontSizeL
            }
            ColumnLayout {
              Layout.fillWidth: true
              Layout.minimumWidth: 0
              spacing: Style.marginXXS
              NText {
                Layout.fillWidth: true
                text: card.modelData.app
                pointSize: Style.fontSizeXS
                color: Color.mOnSurfaceVariant
                elide: Text.ElideRight
              }
              NText {
                Layout.fillWidth: true
                visible: text !== ""
                text: card.modelData.title
                pointSize: Style.fontSizeM
                font.weight: Style.fontWeightSemiBold
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
              }
              NText {
                Layout.fillWidth: true
                visible: text !== ""
                text: card.modelData.text
                pointSize: Style.fontSizeS
                color: Color.mOnSurfaceVariant
                wrapMode: Text.Wrap
                maximumLineCount: 6
                elide: Text.ElideRight
              }
            }
            ColumnLayout {
              Layout.alignment: Qt.AlignTop
              spacing: 0
              NIconButton {
                visible: card.modelData.dismissable
                icon: "x"
                baseSize: Style.baseWidgetSize * 0.8
                onClicked: KdeConnectService.dismissNotification(card.modelData.id)
              }
              NIconButton {
                visible: card.modelData.repliable
                icon: "arrow-back-up"
                baseSize: Style.baseWidgetSize * 0.8
                onClicked: root.replying = card.replyOpen ? "" : card.modelData.id
              }
            }
          }

          KdeConnectComposer {
            Layout.fillWidth: true
            visible: card.replyOpen
            placeholder: I18n.tr("kdeconnect.notifications.reply")
            onVisibleChanged: {
              if (visible)
                focusField();
            }
            onSend: text => {
              KdeConnectService.replyNotification(card.modelData.id, text);
              root.replying = "";
            }
          }
        }
      }
    }
  }
}
