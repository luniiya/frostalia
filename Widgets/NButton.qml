import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Services.UI

Item {
  id: root

  // Public properties
  property string text: ""
  property string icon: ""
  property var tooltipText
  property color backgroundColor: ShellColors.mPrimary
  property color textColor: ShellColors.mOnPrimary
  // Material: outlined buttons become tonal buttons (tinted pill, no border)
  readonly property bool _tonal: Style.materialControls && outlined
  property color hoverColor: Style.materialControls ? (outlined ? Qt.alpha(backgroundColor, 0.16) : backgroundColor) : ShellColors.mHover
  property color textHoverColor: Style.materialControls ? (outlined ? ShellColors.mOnSurface : textColor) : ShellColors.mOnHover
  property real fontSize: Style.fontSizeM
  property int fontWeight: Style.fontWeightSemiBold
  property real iconSize: Style.fontSizeL
  property bool outlined: false
  property int horizontalAlignment: Qt.AlignHCenter
  property real buttonRadius: Style.materialControls ? Style.iRadiusL : Style.iRadiusS

  // Signals
  signal clicked
  signal rightClicked
  signal middleClicked
  signal entered
  signal exited

  // Internal properties
  property bool hovered: false
  readonly property color contentColor: {
    if (!root.enabled) {
      return ShellColors.mOnSurfaceVariant;
    }
    if (root.hovered && !Style.keycapControls) {
      return root.textHoverColor;
    }
    if (root._tonal) {
      return ShellColors.mOnSurface;
    }
    if (root.outlined) {
      return root.backgroundColor;
    }
    return root.textColor;
  }

  // Dimensions - include margin so border renders cleanly at fractional scales
  implicitWidth: bg.implicitWidth + 2 * Style.borderS
  implicitHeight: bg.implicitHeight + 2 * Style.borderS

  opacity: enabled ? 1.0 : 0.6
  scale: Style.materialControls && mouseArea.pressed ? 0.97 : 1
  Behavior on scale {
    enabled: Style.materialControls
    NumberAnimation {
      duration: Style.animationFast
      easing.type: Easing.OutCubic
    }
  }

  Rectangle {
    id: bg
    anchors.fill: parent
    anchors.margins: Style.borderS

    implicitWidth: contentRow.implicitWidth + (root.fontSize * 2)
    implicitHeight: contentRow.implicitHeight + (root.fontSize)

    radius: root.buttonRadius
    color: {
      if (Style.keycapControls)
        return "transparent";
      if (!root.enabled)
        return root.outlined ? "transparent" : Qt.lighter(ShellColors.mSurfaceVariant, 1.2);
      if (root.hovered)
        return root.hoverColor;
      if (root._tonal)
        return Qt.alpha(root.backgroundColor, 0.16);
      return root.outlined ? "transparent" : root.backgroundColor;
    }

    border.width: root.outlined && !root._tonal && !Style.keycapControls ? Style.borderS : 0
    border.color: {
      if (!root.enabled)
        return ShellColors.mOutline;
      if (root.hovered)
        return root.hoverColor;
      return root.outlined ? root.backgroundColor : "transparent";
    }

    Behavior on color {
      enabled: !ShellColors.isTransitioning
      ColorAnimation {
        duration: Style.animationFast
        easing.type: Easing.OutCubic
      }
    }

    Behavior on border.color {
      enabled: !ShellColors.isTransitioning
      ColorAnimation {
        duration: Style.animationFast
        easing.type: Easing.OutCubic
      }
    }

    NMaterialStateLayer {
      hovered: root.hovered
      pressed: mouseArea.pressed
      tint: root._tonal ? ShellColors.mOnSurface : (root.outlined ? root.backgroundColor : root.textColor)
    }

    // Keycap renderer: filled key with a hard shadow that sinks while pressed.
    // Outlined buttons become surface keys with the accent as content color.
    Loader {
      id: keycap
      active: Style.keycapControls
      anchors.fill: parent
      z: -1
      readonly property real sink: item ? item.sink : 0
      sourceComponent: NKeycap {
        readonly property color baseFill: !root.enabled ? ShellColors.mSurfaceVariant : (root.outlined ? ShellColors.mSurface : root.backgroundColor)
        fillColor: root.hovered && root.enabled && !root.outlined ? Qt.lighter(baseFill, 1.08) : baseFill
        inkColor: KeycapKit.ink
        ringColor: KeycapKit.ringFor(baseFill)
        radius: root.buttonRadius
        outlineWidth: Style.keycapOutline
        ringWidth: Style.keycapRing
        depth: Style.keycapDepth
        pressedDepth: Style.keycapPressedDepth
        hoverLift: Style.keycapHoverLift
        pressed: mouseArea.pressed
        hovered: root.hovered && root.enabled
        duration: Style.animationFast
        overshoot: KeycapKit.overshoot
      }
    }

    // Content
    RowLayout {
      id: contentRow
      anchors.verticalCenter: parent.verticalCenter
      anchors.verticalCenterOffset: keycap.sink
      anchors.left: root.horizontalAlignment === Qt.AlignLeft ? parent.left : undefined
      anchors.horizontalCenter: root.horizontalAlignment === Qt.AlignHCenter ? parent.horizontalCenter : undefined
      anchors.leftMargin: root.horizontalAlignment === Qt.AlignLeft ? Style.marginL : 0
      spacing: Style.marginXS

      // Icon (optional)
      NIcon {
        Layout.alignment: Qt.AlignVCenter
        visible: root.icon !== ""
        icon: root.icon
        pointSize: root.iconSize
        color: root.contentColor

        Behavior on color {
          enabled: !ShellColors.isTransitioning
          ColorAnimation {
            duration: Style.animationFast
            easing.type: Easing.OutCubic
          }
        }
      }

      // Text
      NText {
        Layout.alignment: Qt.AlignVCenter
        visible: root.text !== ""
        text: root.text
        pointSize: root.fontSize
        font.weight: root.fontWeight
        color: root.contentColor

        Behavior on color {
          enabled: !ShellColors.isTransitioning
          ColorAnimation {
            duration: Style.animationFast
            easing.type: Easing.OutCubic
          }
        }
      }
    }

    // Mouse interaction
    MouseArea {
      id: mouseArea
      anchors.fill: parent
      enabled: root.enabled
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
      cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

      onEntered: {
        root.hovered = root.enabled ? true : false;
        root.entered();
        if (root.hovered && root.tooltipText && (!Array.isArray(root.tooltipText) || root.tooltipText.length > 0)) {
          TooltipService.show(root, root.tooltipText);
        }
      }
      onExited: {
        root.hovered = false;
        root.exited();
        if (root.tooltipText && (!Array.isArray(root.tooltipText) || root.tooltipText.length > 0)) {
          TooltipService.hide();
        }
      }
      onPressed: mouse => {
        if (root.tooltipText && (!Array.isArray(root.tooltipText) || root.tooltipText.length > 0)) {
          TooltipService.hide();
        }
        if (mouse.button === Qt.LeftButton) {
          root.clicked();
        } else if (mouse.button == Qt.RightButton) {
          root.rightClicked();
        } else if (mouse.button == Qt.MiddleButton) {
          root.middleClicked();
        }
      }

      onCanceled: {
        root.hovered = false;
        if (root.tooltipText && (!Array.isArray(root.tooltipText) || root.tooltipText.length > 0)) {
          TooltipService.hide();
        }
      }
    }
  }
}
