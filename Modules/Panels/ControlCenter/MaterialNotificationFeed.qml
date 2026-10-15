import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../../Helpers/ControlCenterLayout.js" as ControlCenterLayout
import qs.Commons
import qs.Modules.Notification
import qs.Services.System
import qs.Widgets

Rectangle {
  id: root
  implicitHeight: ControlCenterLayout.notificationHeight(NotificationService.historyModel.count, Style.uiScaleRatio)
  radius: Style.radiusM
  color: Color.mSurfaceVariant

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: Style.marginS
    spacing: Style.marginS
    ListView {
      id: list
      Layout.fillWidth: true
      Layout.fillHeight: true
      clip: true
      spacing: Style.marginXS
      model: NotificationService.historyModel
      ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
      }
      delegate: Rectangle {
        required property var model
        width: list.width
        height: content.implicitHeight + Style.margin2M
        radius: Style.radiusS
        color: Qt.tint(Color.mSurfaceVariant, Qt.alpha(Color.mOnSurface, 0.035))
        MaterialNotificationContent {
          id: content
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.margins: Style.marginM
          notificationData: model
          compact: true
          onDismissRequested: NotificationService.removeFromHistory(model.id)
          onActionRequested: identifier => {
            if (NotificationService.invokeAction(model.id, identifier))
              NotificationService.removeFromHistory(model.id);
          }
        }
      }
      NText {
        anchors.centerIn: parent
        visible: list.count === 0
        text: I18n.tr("notifications.panel.no-notifications")
        color: Color.mOnSurfaceVariant
        pointSize: Style.fontSizeS
      }
    }
    RowLayout {
      Layout.fillWidth: true
      NIconButton {
        icon: NotificationService.doNotDisturb ? "bell-off" : "bell"
        tooltipText: I18n.tr("common.notifications")
        onClicked: NotificationService.doNotDisturb = !NotificationService.doNotDisturb
      }
      NText {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        text: I18n.tr("control-center.notification-count", {
                        count: NotificationService.historyModel.count
                      })
        pointSize: Style.fontSizeS
      }
      NIconButton {
        icon: "trash"
        tooltipText: I18n.tr("actions.clear-history")
        enabled: list.count > 0
        onClicked: NotificationService.clearHistory()
      }
    }
  }
}
