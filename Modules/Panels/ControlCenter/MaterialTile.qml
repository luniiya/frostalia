import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

// Material quick settings tile: compact (icon only) or wide (icon, title and
// subtitle). Shared by the control center shortcuts and the KDE Connect panel.
Rectangle {
  id: root
  property string icon: "settings"
  property string title: ""
  property string subtitle: ""
  property bool active: false
  property bool wide: false
  property bool available: true
  property bool interactive: true
  property bool showContent: true
  signal clicked(string button)

  readonly property color contentColor: active ? ShellColors.mOnPrimary : ShellColors.mOnSurface

  implicitHeight: Math.round(60 * Style.uiScaleRatio)
  radius: Math.min(Style.iRadiusL, height / 2)
  color: active ? ShellColors.mPrimary : Qt.tint(ShellColors.mSurfaceVariant, Qt.alpha(ShellColors.mOnSurface, 0.035))
  opacity: available ? 1 : 0.45
  Accessible.name: subtitle ? title + ", " + subtitle : title
  Accessible.role: Accessible.Button
  Accessible.onPressAction: root.clicked("left")

  NKeycapCard {}

  NMaterialStateLayer {
    hovered: pointer.containsMouse
    pressed: pointer.pressed
    tint: root.contentColor
  }

  RowLayout {
    anchors.fill: parent
    anchors.margins: Math.round(12 * Style.uiScaleRatio)
    spacing: Style.marginM
    visible: root.showContent
    NIcon {
      Layout.alignment: Qt.AlignCenter
      Layout.fillWidth: !root.wide
      horizontalAlignment: Text.AlignHCenter
      icon: root.icon
      pointSize: Style.fontSizeXL
      color: root.contentColor
    }
    ColumnLayout {
      visible: root.wide
      Layout.fillWidth: true
      Layout.minimumWidth: 0
      spacing: 0
      NText {
        Layout.fillWidth: true
        text: root.title
        pointSize: Style.fontSizeS
        color: root.contentColor
        elide: Text.ElideRight
      }
      NText {
        Layout.fillWidth: true
        visible: text !== ""
        text: root.subtitle
        pointSize: Style.fontSizeXS
        color: root.active ? ShellColors.mOnPrimary : ShellColors.mOnSurfaceVariant
        elide: Text.ElideRight
      }
    }
  }

  MouseArea {
    id: pointer
    anchors.fill: parent
    enabled: root.interactive && root.available
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: mouse => root.clicked(mouse.button === Qt.RightButton ? "right" : mouse.button === Qt.MiddleButton ? "middle" : "left")
  }
}
