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
  // Hover colors, for styles that tint on hover
  property color hoverColor: outlined ? Qt.alpha(backgroundColor, 0.16) : backgroundColor
  property color textHoverColor: outlined ? ShellColors.mOnSurface : textColor
  property real fontSize: Style.fontSizeM
  property int fontWeight: Style.fontWeightSemiBold
  property real iconSize: Style.fontSizeL
  property bool outlined: false
  property int horizontalAlignment: Qt.AlignHCenter
  property real buttonRadius: Style.iRadiusL

  // Signals
  signal clicked
  signal rightClicked
  signal middleClicked
  signal entered
  signal exited

  // Internal properties
  property bool hovered: false
  readonly property bool pressed: mouseArea.pressed
  // The style's skin (Styles/<style>/Button.qml) picks the content color
  readonly property color contentColor: skin.loaded ? skin.item.contentColor : textColor

  // Dimensions - include margin so border renders cleanly at fractional scales
  implicitWidth: bg.implicitWidth + 2 * Style.borderS
  implicitHeight: bg.implicitHeight + 2 * Style.borderS

  opacity: enabled ? 1.0 : 0.6
  scale: skin.loaded ? skin.item.controlScale : 1
  Behavior on scale {
    NumberAnimation {
      duration: Style.animationFast
      easing.type: Easing.OutCubic
    }
  }

  Item {
    id: bg
    anchors.fill: parent
    anchors.margins: Style.borderS

    implicitWidth: contentRow.implicitWidth + (root.fontSize * 2)
    implicitHeight: contentRow.implicitHeight + (root.fontSize)

    NStyleSkin {
      id: skin
      name: "Button"
      control: root
      z: -1
    }

    // Content
    RowLayout {
      id: contentRow
      anchors.verticalCenter: parent.verticalCenter
      anchors.verticalCenterOffset: skin.loaded ? skin.item.sink : 0
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
