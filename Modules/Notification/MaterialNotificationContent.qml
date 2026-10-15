import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

// The popup lifecycle and gestures live in Notification.qml; this renderer owns
// only the Material card content and forwards user actions to that shared shell.
ColumnLayout {
  id: root

  property var notificationData: ({})
  property bool compact: false
  signal actionRequested(string identifier)
  signal dismissRequested
  readonly property var actions: {
    try {
      return JSON.parse(notificationData.actionsJson || "[]");
    } catch (error) {
      return [];
    }
  }

  spacing: Style.marginS

  RowLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NImageRounded {
      Layout.preferredWidth: Math.round(28 * Style.uiScaleRatio)
      Layout.preferredHeight: Layout.preferredWidth
      radius: width / 2
      imagePath: root.notificationData.originalImage || ""
      borderWidth: 0
      fallbackIcon: "bell"
      fallbackIconSize: 18
    }

    NText {
      Layout.fillWidth: true
      text: root.notificationData.appName || I18n.tr("common.notifications")
      color: root.notificationData.urgency === 2 ? Color.mError : Color.mPrimary
      pointSize: Style.fontSizeXS
      font.weight: Style.fontWeightMedium
      elide: Text.ElideRight
    }

    NText {
      text: Time.formatRelativeTime(root.notificationData.timestamp)
      color: Color.mOnSurfaceVariant
      pointSize: Style.fontSizeXXS
    }

    NIconButton {
      icon: "close"
      baseSize: Style.baseWidgetSize * 0.6
      tooltipText: I18n.tr("tooltips.dismiss-notification")
      onClicked: root.dismissRequested()
    }
  }

  NText {
    Layout.fillWidth: true
    text: root.notificationData.summary || I18n.tr("common.no-summary")
    pointSize: Style.fontSizeM
    font.weight: Style.fontWeightSemiBold
    color: Color.mOnSurface
    textFormat: Text.StyledText
    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
    maximumLineCount: root.compact ? 1 : 3
    elide: Text.ElideRight
  }

  NText {
    Layout.fillWidth: true
    visible: text.length > 0
    text: root.notificationData.body || ""
    pointSize: Style.fontSizeM
    color: Color.mOnSurfaceVariant
    textFormat: Text.StyledText
    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
    maximumLineCount: root.compact ? 2 : 5
    elide: Text.ElideRight
  }

  Flow {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginS
    visible: !root.compact && root.actions.length > 0
    spacing: Style.marginS

    Repeater {
      model: root.actions
      NButton {
        required property var modelData
        text: modelData.text || I18n.tr("common.actions")
        fontSize: Style.fontSizeS
        backgroundColor: Qt.alpha(Color.mPrimary, 0.12)
        textColor: Color.mPrimary
        buttonRadius: height / 2
        implicitHeight: Math.round(34 * Style.uiScaleRatio)
        onClicked: root.actionRequested(modelData.identifier)
      }
    }
  }
}
