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

  // Material: filled tonal icon button that stays visible on surface-variant pages
  property color colorBg: Style.materialControls ? ShellColors.mTonalContainer : ShellColors.smartAlpha(ShellColors.mSurfaceVariant)
  property color colorFg: ShellColors.mPrimary
  property color colorBgHover: Style.materialControls ? colorBg : ShellColors.mHover
  property color colorFgHover: Style.materialControls ? colorFg : ShellColors.mOnHover
  property color colorBorder: ShellColors.mOutline
  property color colorBorderHover: ShellColors.mOutline
  property real customRadius: -1 // -1 means use default (iRadiusL), otherwise use this value
  // Style-specific face (UiStyles `barViews`) for bar buttons, the state it shows and its depth
  property string faceView: ""
  property var faceData: ({})
  property real faceDepth: Style.keycapDepth
  readonly property bool pressed: iconMouse.pressed && enabled
  readonly property bool faceActive: styleFace.active

  // Expose border properties for backwards compatibility (aliases to visualButton)
  property alias border: visualButton.border
  property alias radius: visualButton.radius
  property alias color: visualButton.color

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

  // Keycap renderer: the button is a key that sinks while pressed
  Loader {
    active: Style.keycapControls && !styleFace.active
    width: root.buttonSize
    height: root.buttonSize
    anchors.centerIn: parent
    sourceComponent: NKeycap {
      readonly property color baseFill: root.colorBg.a > 0.05 ? Qt.rgba(root.colorBg.r, root.colorBg.g, root.colorBg.b, 1) : KeycapKit.fill
      y: -Math.round(depth / 2)
      fillColor: baseFill
      inkColor: KeycapKit.ink
      ringColor: KeycapKit.ringFor(baseFill)
      radius: Math.min((root.customRadius >= 0 ? root.customRadius : Style.iRadiusL), width / 2)
      outlineWidth: Style.keycapOutline
      ringWidth: Style.keycapRing
      depth: Math.min(root.faceDepth, Style.keycapDepth)
      pressedDepth: Style.keycapPressedDepth
      hoverLift: Style.keycapHoverLift
      pressed: root.pressed
      hovered: root.hovering
      duration: Style.animationFast
      overshoot: KeycapKit.overshoot

      NIcon {
        icon: root.icon
        pointSize: Style.toOdd(root.buttonSize * 0.48)
        applyUiScale: root.applyUiScale
        color: root.colorFg
        x: Style.pixelAlignCenter(parent.width, width)
        y: Style.pixelAlignCenter(parent.height, contentHeight)
      }
    }
  }

  // Visual button - stays at buttonSize, centered in parent
  Rectangle {
    id: visualButton
    visible: !Style.keycapControls && !styleFace.active
    width: root.buttonSize
    height: root.buttonSize
    anchors.centerIn: parent

    color: root.enabled && root.hovering ? colorBgHover : colorBg
    radius: Math.min((customRadius >= 0 ? customRadius : Style.iRadiusL), width / 2)
    border.color: root.enabled && root.hovering ? colorBorderHover : colorBorder
    border.width: Style.materialControls ? 0 : Style.borderS

    Behavior on color {
      enabled: !ShellColors.isTransitioning
      ColorAnimation {
        duration: Style.animationFast
        easing.type: Easing.InOutQuad
      }
    }

    NMaterialStateLayer {
      hovered: root.hovering
      pressed: iconMouse.pressed && root.enabled
      tint: root.colorFg
    }

    NIcon {
      icon: root.icon
      pointSize: Style.toOdd(visualButton.width * 0.48)
      applyUiScale: root.applyUiScale
      color: root.enabled && root.hovering ? colorFgHover : colorFg
      // Pixel-perfect centering
      x: Style.pixelAlignCenter(visualButton.width, width)
      y: Style.pixelAlignCenter(visualButton.height, contentHeight)

      Behavior on color {
        enabled: !ShellColors.isTransitioning
        ColorAnimation {
          duration: Style.animationFast
          easing.type: Easing.InOutQuad
        }
      }
    }
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
