import QtQuick
import QtQuick.Layouts
import "../../../Helpers/KdeConnect.js" as KdeConnect
import qs.Commons
import qs.Services.Networking
import qs.Widgets

// Incoming pairing requests and nearby devices that can be paired.
ColumnLayout {
  id: root
  readonly property var candidates: KdeConnectService.unpairedDevices
  readonly property bool empty: candidates.length === 0

  spacing: Style.marginS

  Repeater {
    model: root.candidates
    NBox {
      id: card
      required property var modelData
      readonly property bool incoming: modelData.pairRequestedByPeer
      readonly property bool waiting: modelData.pairRequested && !incoming
      Layout.fillWidth: true
      implicitHeight: cardBody.implicitHeight + Style.margin2M
      ColumnLayout {
        id: cardBody
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Style.marginM
        spacing: Style.marginS
        RowLayout {
          Layout.fillWidth: true
          spacing: Style.marginM
          NIcon {
            icon: KdeConnect.deviceIcon(Object.assign({}, card.modelData, {
                                                        paired: true
                                                      }))
            pointSize: Style.fontSizeXL
            color: card.incoming ? ShellColors.mPrimary : ShellColors.mOnSurface
          }
          ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            NText {
              Layout.fillWidth: true
              text: card.modelData.name
              pointSize: Style.fontSizeM
              font.weight: Style.fontWeightSemiBold
              elide: Text.ElideRight
            }
            NText {
              Layout.fillWidth: true
              text: card.incoming ? I18n.tr("kdeconnect.pairing.wants-to-pair") : card.waiting ? I18n.tr("kdeconnect.pairing.waiting") : I18n.tr("kdeconnect.pairing.available")
              pointSize: Style.fontSizeXS
              color: card.incoming ? ShellColors.mPrimary : ShellColors.mOnSurfaceVariant
              elide: Text.ElideRight
            }
          }
          NButton {
            visible: !card.incoming
            text: card.waiting ? I18n.tr("common.cancel") : I18n.tr("common.pair")
            outlined: card.waiting
            onClicked: card.waiting ? KdeConnectService.rejectPairing(card.modelData.id) : KdeConnectService.requestPairing(card.modelData.id)
          }
        }
        // Both screens show this key; compare before accepting.
        NText {
          Layout.fillWidth: true
          visible: (card.incoming || card.waiting) && card.modelData.verificationKey !== ""
          text: I18n.tr("kdeconnect.pairing.verification-key", {
                          key: card.modelData.verificationKey
                        })
          pointSize: Style.fontSizeXS
          font.family: Style.fontFixed
          color: ShellColors.mOnSurfaceVariant
          wrapMode: Text.WrapAnywhere
        }
        RowLayout {
          Layout.fillWidth: true
          visible: card.incoming
          spacing: Style.marginS
          NButton {
            Layout.fillWidth: true
            text: I18n.tr("kdeconnect.pairing.accept")
            icon: "check"
            onClicked: KdeConnectService.acceptPairing(card.modelData.id)
          }
          NButton {
            Layout.fillWidth: true
            text: I18n.tr("kdeconnect.pairing.reject")
            icon: "x"
            outlined: true
            onClicked: KdeConnectService.rejectPairing(card.modelData.id)
          }
        }
      }
    }
  }
}
