import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

// Centered icon, message and optional action button.
ColumnLayout {
  id: root
  property string icon: "device-mobile-off"
  property string title: ""
  property string description: ""
  property string actionText: ""
  property string actionIcon: ""
  signal actionClicked

  spacing: Style.marginS

  NIcon {
    Layout.alignment: Qt.AlignHCenter
    icon: root.icon
    pointSize: Style.fontSizeXXXL * 1.4
    color: ShellColors.mOnSurfaceVariant
  }
  NText {
    Layout.alignment: Qt.AlignHCenter
    Layout.fillWidth: true
    horizontalAlignment: Text.AlignHCenter
    text: root.title
    pointSize: Style.fontSizeL
    font.weight: Style.fontWeightSemiBold
    wrapMode: Text.Wrap
  }
  NText {
    Layout.alignment: Qt.AlignHCenter
    Layout.fillWidth: true
    visible: text !== ""
    horizontalAlignment: Text.AlignHCenter
    text: root.description
    pointSize: Style.fontSizeS
    color: ShellColors.mOnSurfaceVariant
    wrapMode: Text.Wrap
  }
  NButton {
    Layout.alignment: Qt.AlignHCenter
    Layout.topMargin: Style.marginS
    visible: root.actionText !== ""
    text: root.actionText
    icon: root.actionIcon
    onClicked: root.actionClicked()
  }
}
