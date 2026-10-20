import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Item {
  id: root

  property var notificationData: ({})
  property bool compact: false
  readonly property var model: notificationData
  signal actionRequested(string identifier)
  signal dismissRequested
  implicitHeight: (compact ? compactContent.implicitHeight : notificationContent.implicitHeight) + Style.margin2M

  // Content
  ColumnLayout {
    id: notificationContent
    visible: !root.compact
    anchors.fill: root
    anchors.margins: Style.marginM
    spacing: Style.marginM

    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginL
      Layout.leftMargin: Style.marginM
      Layout.rightMargin: Style.marginM
      Layout.topMargin: Style.marginM
      Layout.bottomMargin: Style.marginM

      NImageRounded {
        Layout.preferredWidth: Math.round(40 * Style.uiScaleRatio)
        Layout.preferredHeight: Math.round(40 * Style.uiScaleRatio)
        Layout.alignment: Qt.AlignVCenter
        radius: Math.min(Style.radiusL, Layout.preferredWidth / 2)
        imagePath: model.originalImage || ""
        borderColor: "transparent"
        borderWidth: 0
        fallbackIcon: "bell"
        fallbackIconSize: 24
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        // Header with urgency indicator
        RowLayout {
          Layout.fillWidth: true
          spacing: Style.marginS

          Rectangle {
            Layout.preferredWidth: 6
            Layout.preferredHeight: 6
            Layout.alignment: Qt.AlignVCenter
            radius: Style.radiusXS
            color: model.urgency === 2 ? ShellColors.mError : model.urgency === 0 ? ShellColors.mOnSurface : ShellColors.mPrimary
          }

          NText {
            text: model.appName || "Unknown App"
            pointSize: Style.fontSizeXS
            font.weight: Style.fontWeightBold
            color: ShellColors.mSecondary
          }

          NText {
            textFormat: Text.PlainText
            text: " " + Time.formatRelativeTime(model.timestamp)
            pointSize: Style.fontSizeXXS
            color: ShellColors.mOnSurfaceVariant
            Layout.alignment: Qt.AlignBottom
          }

          Item {
            Layout.fillWidth: true
          }
        }

        NText {
          text: model.summary || I18n.tr("common.no-summary")
          pointSize: Style.fontSizeM
          font.weight: Style.fontWeightMedium
          color: ShellColors.mOnSurface
          textFormat: Text.StyledText
          wrapMode: Text.WrapAtWordBoundaryOrAnywhere
          maximumLineCount: 3
          elide: Text.ElideRight
          visible: text.length > 0
          Layout.fillWidth: true
          Layout.rightMargin: Style.marginM
        }

        NText {
          text: model.body || ""
          pointSize: Style.fontSizeM
          color: ShellColors.mOnSurface
          textFormat: Text.StyledText
          wrapMode: Text.WrapAtWordBoundaryOrAnywhere

          maximumLineCount: 5
          elide: Text.ElideRight
          visible: text.length > 0
          Layout.fillWidth: true
          Layout.rightMargin: Style.marginXL
        }

        // Actions
        Flow {
          Layout.fillWidth: true
          spacing: Style.marginS
          Layout.topMargin: Style.marginM
          flow: Flow.LeftToRight

          property string parentNotificationId: root.notificationData.id || ""
          property var parsedActions: {
            try {
              return model.actionsJson ? JSON.parse(model.actionsJson) : [];
            } catch (e) {
              return [];
            }
          }
          visible: parsedActions.length > 0

          Repeater {
            model: parent.parsedActions

            delegate: NButton {
              property var actionData: modelData

              text: {
                var actionText = actionData.text || "Open";
                if (actionText.includes(",")) {
                  return actionText.split(",")[1] || actionText;
                }
                return actionText;
              }
              fontSize: Style.fontSizeS
              backgroundColor: ShellColors.mPrimary
              textColor: hovered ? ShellColors.mOnHover : ShellColors.mOnPrimary
              hoverColor: ShellColors.mHover
              outlined: false
              implicitHeight: 24
              onClicked: {
                root.actionRequested(actionData.identifier);
              }
            }
          }
        }
      }
    }
  }

  // Close button
  NIconButton {
    visible: !root.compact
    icon: "close"
    tooltipText: I18n.tr("tooltips.dismiss-notification")
    baseSize: Style.baseWidgetSize * 0.6
    anchors.top: root.top
    anchors.topMargin: Style.marginXL
    anchors.right: root.right
    anchors.rightMargin: Style.marginXL

    onClicked: {
      root.dismissRequested();
    }
  }

  // Compact content
  RowLayout {
    id: compactContent
    visible: root.compact
    anchors.fill: root
    anchors.margins: Style.marginM
    spacing: Style.marginS

    NImageRounded {
      Layout.preferredWidth: Math.round(24 * Style.uiScaleRatio)
      Layout.preferredHeight: Math.round(24 * Style.uiScaleRatio)
      Layout.alignment: Qt.AlignVCenter
      radius: Style.radiusXS
      imagePath: model.originalImage || ""
      borderColor: "transparent"
      borderWidth: 0
      fallbackIcon: "bell"
      fallbackIconSize: 16
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.marginXS

      NText {
        text: model.summary || I18n.tr("common.no-summary")
        pointSize: Style.fontSizeM
        font.weight: Style.fontWeightMedium
        color: ShellColors.mOnSurface
        textFormat: Text.StyledText
        maximumLineCount: 1
        elide: Text.ElideRight
        Layout.fillWidth: true
      }

      NText {
        visible: model.body && model.body.length > 0
        Layout.fillWidth: true
        text: model.body || ""
        pointSize: Style.fontSizeS
        color: ShellColors.mOnSurfaceVariant
        textFormat: Text.StyledText
        wrapMode: Text.Wrap
        maximumLineCount: 2
        elide: Text.ElideRight
      }
    }
  }
}
