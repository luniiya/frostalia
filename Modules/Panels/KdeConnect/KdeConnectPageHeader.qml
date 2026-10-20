import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

// Back button, title and optional trailing buttons for drill-down pages.
RowLayout {
  id: root
  required property var nav
  property string title: ""
  property string subtitle: ""
  default property alias actions: trailing.data

  spacing: Style.marginS

  NIconButton {
    icon: "arrow-left"
    baseSize: Style.baseWidgetSize * 0.9
    onClicked: root.nav.pop()
  }

  ColumnLayout {
    Layout.fillWidth: true
    Layout.minimumWidth: 0
    spacing: 0
    NText {
      Layout.fillWidth: true
      text: root.title
      pointSize: Style.fontSizeL
      font.weight: Style.fontWeightSemiBold
      elide: Text.ElideRight
    }
    NText {
      Layout.fillWidth: true
      visible: text !== ""
      text: root.subtitle
      pointSize: Style.fontSizeXS
      color: ShellColors.mOnSurfaceVariant
      elide: Text.ElideRight
    }
  }

  RowLayout {
    id: trailing
    spacing: Style.marginXS
  }
}
