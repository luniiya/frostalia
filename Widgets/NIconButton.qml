import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.Commons
import qs.Services.UI

Item {
  id: root

  property real baseSize: Style.baseWidgetSize
  property bool applyUiScale: true

  property string icon
  property var tooltipText
  property string tooltipDirection: "auto"
  property bool allowClickWhenDisabled: false
  property bool handleWheel: false
  property bool hovering: false

  // The style's skin (Styles/<style>/IconButton.qml) picks the default background
  property color colorBg: skin.loaded ? skin.item.defaultBackground : ShellColors.mTonalContainer
  property color colorFg: ShellColors.mPrimary
  property color colorBgHover: colorBg
  property color colorFgHover: colorFg
  property color colorBorder: ShellColors.mOutline
  property color colorBorderHover: ShellColors.mOutline
  property real customRadius: -1 // -1 means use default (iRadiusL), otherwise use this value
  // Style-specific face (UiStyles `barViews`) for bar buttons, the state it shows and its depth
  property string faceView: ""
  property var faceData: ({})
  property real faceDepth: Style.faceDepth
  readonly property bool pressed: iconMouse.pressed && enabled
  readonly property bool faceActive: styleFace.active

  // Background, shape and border the skin draws (styles may ignore some of them)
  property alias border: borderSpec.border
  property real radius: Math.min((customRadius >= 0 ? customRadius : Style.iRadiusL), buttonSize / 2)
  property color color: enabled && hovering ? colorBgHover : colorBg

  signal entered
  signal exited
  signal clicked
  signal rightClicked
  signal middleClicked
  signal wheel(int angleDelta)

  // Calculate button size based on settings
  readonly property real buttonSize: applyUiScale ? Style.toOdd(baseSize * Style.uiScaleRatio) : Style.toOdd(baseSize)

  // Size: use implicit width/height which layout can override
  // BarWidgetLoader sets explicit width/height to extend click area
  implicitWidth: buttonSize
  implicitHeight: buttonSize

  opacity: enabled ? 1.0 : 0.6

  // Style face for this button (bar widgets), drawn instead of the visual button
  NStyleFace {
    id: styleFace
    view: root.faceView
    host: root
    hovered: root.hovering
    pressed: root.pressed
    faceData: root.faceData
    depth: root.faceDepth
    width: root.buttonSize
    height: root.buttonSize
    anchors.centerIn: parent
  }

  // Only holds the border settings for the skin
  Rectangle {
    id: borderSpec
    visible: false
    border.color: root.enabled && root.hovering ? root.colorBorderHover : root.colorBorder
    border.width: 0
  }

  NStyleSkin {
    id: skin
    name: "IconButton"
    control: root
    active: !styleFace.active
    anchors.fill: undefined
    width: root.buttonSize
    height: root.buttonSize
    anchors.centerIn: parent
  }

  // MouseArea fills root (extends beyond visual button for bar click area)
  MouseArea {
    id: iconMouse
    // Always enabled to allow hover/tooltip even when the button is disabled
    enabled: true
    anchors.fill: parent
    cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    hoverEnabled: true
    onEntered: {
      hovering = root.enabled ? true : false;
      if (hovering && tooltipText && (!Array.isArray(tooltipText) || tooltipText.length > 0)) {
        TooltipService.show(root, tooltipText, tooltipDirection);
      }
      root.entered();
    }
    onExited: {
      hovering = false;
      if (tooltipText && (!Array.isArray(tooltipText) || tooltipText.length > 0)) {
        TooltipService.hide(root);
      }
      root.exited();
    }
    onClicked: mouse => {
      if (tooltipText && (!Array.isArray(tooltipText) || tooltipText.length > 0)) {
        TooltipService.hide(root);
      }
      if (!root.enabled && !allowClickWhenDisabled) {
        return;
      }
      if (mouse.button === Qt.LeftButton) {
        root.clicked();
      } else if (mouse.button === Qt.RightButton) {
        root.rightClicked();
      } else if (mouse.button === Qt.MiddleButton) {
        root.middleClicked();
      }
    }
    onWheel: wheel => {
      if (root.handleWheel) {
        root.wheel(wheel.angleDelta.y);
      }
      wheel.accepted = false;
    }
  }
}
