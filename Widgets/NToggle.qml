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

  readonly property bool pressed: toggleMouse.pressed
  readonly property var geometry: Style.getToggleGeometry(baseSize, checked, pressed)

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

  Item {
    id: switcher

    opacity: enabled ? 1.0 : 0.6
    Layout.alignment: Qt.AlignVCenter
    Layout.margins: Style.borderS
    implicitWidth: root.geometry.width
    implicitHeight: root.geometry.height

    // Track and handle (Styles/<style>/Toggle.qml)
    NStyleSkin {
      name: "Toggle"
      control: root
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
