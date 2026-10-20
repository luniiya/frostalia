import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

RowLayout {
  id: root

  property string label: ""
  property string description: ""
  property string icon: ""
  property bool checked: false
  property bool hovering: false
  property int baseSize: Math.round(Style.baseWidgetSize * Style.toggleStyle.sizeRatio * Style.uiScaleRatio)
  property var defaultValue: undefined
  property string settingsPath: ""

  readonly property var geometry: Style.getToggleGeometry(baseSize, checked, toggleMouse.pressed)

  signal toggled(bool checked)
  signal entered
  signal exited

  Layout.fillWidth: true
  spacing: Style.marginM

  readonly property bool isValueChanged: (defaultValue !== undefined) && (checked !== defaultValue)
  readonly property string indicatorTooltip: defaultValue !== undefined ? I18n.tr("panels.indicator.default-value", {
                                                                                    "value": typeof defaultValue === "boolean" ? (defaultValue ? "true" : "false") : String(defaultValue)
                                                                                  }) : ""

  NLabel {
    Layout.fillWidth: true
    label: root.label
    description: root.description
    icon: root.icon
    iconColor: root.checked ? ShellColors.mPrimary : ShellColors.mOnSurface
    visible: root.label !== "" || root.description !== ""
    showIndicator: root.isValueChanged
    indicatorTooltip: root.indicatorTooltip
  }

  Rectangle {
    id: switcher

    opacity: enabled ? 1.0 : 0.6
    Layout.alignment: Qt.AlignVCenter
    Layout.margins: Style.borderS
    implicitWidth: root.geometry.width
    implicitHeight: root.geometry.height
    radius: Math.min(Style.iRadiusL, height / 2)
    color: root.checked ? ShellColors.mPrimary : (Style.materialControls ? ShellColors.mSurfaceVariant : ShellColors.mSurface)
    border.color: Style.materialControls && root.checked ? ShellColors.mPrimary : ShellColors.mOutline
    border.width: Style.materialControls ? Style.toggleStyle.border * root.baseSize / 26 : Style.borderS

    Behavior on color {
      ColorAnimation {
        duration: Style.animationFast
      }
    }

    Behavior on border.color {
      ColorAnimation {
        duration: Style.animationFast
      }
    }

    Rectangle {
      implicitWidth: root.geometry.handle
      implicitHeight: root.geometry.handle
      radius: Math.min(Style.iRadiusL, height / 2)
      color: root.checked ? ShellColors.mOnPrimary : (Style.materialControls ? ShellColors.mOutline : ShellColors.mPrimary)
      border.color: root.checked ? ShellColors.mSurface : ShellColors.mSurface
      border.width: Style.materialControls ? 0 : Style.borderM
      anchors.verticalCenter: parent.verticalCenter
      anchors.verticalCenterOffset: 0
      x: root.geometry.x

      NIcon {
        anchors.centerIn: parent
        visible: Style.materialControls && root.checked
        icon: "check"
        pointSize: parent.width * 0.55 / Style.uiScaleRatio
        color: ShellColors.mPrimary
      }

      Behavior on implicitWidth {
        enabled: Style.materialControls
        NumberAnimation {
          duration: Style.animationFast
          easing.type: Easing.OutCubic
        }
      }
      Behavior on implicitHeight {
        enabled: Style.materialControls
        NumberAnimation {
          duration: Style.animationFast
          easing.type: Easing.OutCubic
        }
      }

      Behavior on x {
        NumberAnimation {
          duration: Style.animationFast
          easing.type: Easing.OutCubic
        }
      }
    }

    MouseArea {
      id: toggleMouse
      enabled: root.enabled
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      hoverEnabled: true
      onEntered: {
        if (!enabled)
          return;
        hovering = true;
        root.entered();
      }
      onExited: {
        if (!enabled)
          return;
        hovering = false;
        root.exited();
      }
      onClicked: {
        if (!enabled)
          return;
        root.toggled(!root.checked);
      }
    }
  }
}
