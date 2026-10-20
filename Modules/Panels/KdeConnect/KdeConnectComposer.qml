import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

// Message field with a send button. Enter sends, Shift+Enter adds a line.
RowLayout {
  id: root
  property string placeholder: I18n.tr("kdeconnect.messages.placeholder")
  property bool canSend: true
  property alias text: field.text
  signal send(string text)

  function submit() {
    const body = field.text.trim();
    if (!body || !root.canSend)
      return;
    root.send(body);
    field.clear();
  }

  function focusField() {
    field.forceActiveFocus();
  }

  spacing: Style.marginS

  Rectangle {
    Layout.fillWidth: true
    Layout.preferredHeight: Math.min(Math.round(140 * Style.uiScaleRatio), Math.max(Math.round(44 * Style.uiScaleRatio), field.implicitHeight + Style.marginS))
    radius: Math.min(Style.iRadiusL, height / 2)
    color: ShellColors.mSurfaceVariant
    border.color: field.activeFocus ? ShellColors.mPrimary : "transparent"
    border.width: Style.borderS

    ScrollView {
      anchors.fill: parent
      anchors.leftMargin: Style.marginM
      anchors.rightMargin: Style.marginM
      ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
      ScrollBar.vertical: NScrollBar {
        policy: ScrollBar.AsNeeded
      }
      TextArea {
        id: field
        placeholderText: root.placeholder
        placeholderTextColor: ShellColors.mOnSurfaceVariant
        color: ShellColors.mOnSurface
        font.family: Style.fontDefault
        font.pointSize: Style.fontSizeM * Style.uiScaleRatio
        wrapMode: TextEdit.Wrap
        background: null
        verticalAlignment: TextEdit.AlignVCenter
        topPadding: Style.marginS
        bottomPadding: Style.marginS
        leftPadding: 0
        rightPadding: 0
        Keys.onPressed: event => {
          if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && !(event.modifiers & Qt.ShiftModifier)) {
            root.submit();
            event.accepted = true;
          }
        }
      }
    }
  }

  NIconButton {
    Layout.alignment: Qt.AlignBottom
    icon: "send"
    baseSize: Math.round(44 * Style.uiScaleRatio)
    applyUiScale: false
    enabled: root.canSend && field.text.trim() !== ""
    colorBg: enabled ? ShellColors.mPrimary : ShellColors.mSurfaceVariant
    colorFg: enabled ? ShellColors.mOnPrimary : ShellColors.mOnSurfaceVariant
    colorBgHover: ShellColors.mPrimary
    colorFgHover: ShellColors.mOnPrimary
    onClicked: root.submit()
  }
}
