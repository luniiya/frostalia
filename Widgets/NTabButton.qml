import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Services.UI
import qs.Widgets

Rectangle {
  id: root

  // Public properties
  property string text: ""
  property string icon: ""
  property var tooltipText
  property bool checked: false
  property int tabIndex: 0
  property real pointSize: Style.fontSizeM
  property bool isFirst: false
  property bool isLast: false

  // Internal state
  property bool isHovered: false

  signal clicked

  // Sizing
  Layout.fillHeight: true
  implicitWidth: contentLayout.implicitWidth + Style.margin2M

  readonly property var groupRadii: Style.getButtonGroupRadii(height, checked, isFirst, isLast)
  property real groupLeftRadius: groupRadii ? groupRadii.left : (isFirst ? Style.iRadiusM : Style.iRadiusXXXS)
  property real groupRightRadius: groupRadii ? groupRadii.right : (isLast ? Style.iRadiusM : Style.iRadiusXXXS)

  topLeftRadius: groupLeftRadius
  bottomLeftRadius: groupLeftRadius
  topRightRadius: groupRightRadius
  bottomRightRadius: groupRightRadius

  color: root.isHovered && !Style.materialControls ? ShellColors.mHover : (root.checked ? ShellColors.mPrimary : (Style.materialControls ? ShellColors.mTonalContainer : ShellColors.smartAlpha(ShellColors.mSurface)))
  border.color: root.checked ? ShellColors.mPrimary : ShellColors.mOutline
  border.width: Style.materialControls ? 0 : Style.borderS

  Behavior on groupLeftRadius {
    enabled: Style.materialControls
    NumberAnimation {
      duration: Style.animationFast
      easing.type: Easing.OutCubic
    }
  }
  Behavior on groupRightRadius {
    enabled: Style.materialControls
    NumberAnimation {
      duration: Style.animationFast
      easing.type: Easing.OutCubic
    }
  }

  Behavior on color {
    enabled: !ShellColors.isTransitioning
    ColorAnimation {
      duration: Style.animationFast
      easing.type: Easing.OutCubic
    }
  }

  NMaterialStateLayer {
    topLeftRadius: root.groupLeftRadius
    bottomLeftRadius: root.groupLeftRadius
    topRightRadius: root.groupRightRadius
    bottomRightRadius: root.groupRightRadius
    hovered: root.isHovered
    pressed: tabMouse.pressed
    tint: root.checked ? ShellColors.mOnPrimary : ShellColors.mPrimary
  }

  // Content
  RowLayout {
    id: contentLayout
    anchors.centerIn: parent
    width: Math.min(implicitWidth, parent.width - Style.margin2S)
    spacing: (root.icon !== "" && root.text !== "") ? Style.marginXS : 0

    NIcon {
      visible: root.icon !== ""
      Layout.alignment: Qt.AlignVCenter
      icon: root.icon
      pointSize: root.pointSize * 1.2
      color: root.isHovered && !Style.materialControls ? ShellColors.mOnHover : (root.checked ? ShellColors.mOnPrimary : ShellColors.mOnSurface)

      Behavior on color {
        enabled: !ShellColors.isTransitioning
        ColorAnimation {
          duration: Style.animationFast
          easing.type: Easing.OutCubic
        }
      }
    }

    NText {
      id: tabText
      visible: root.text !== ""
      Layout.alignment: Qt.AlignVCenter
      text: root.text
      pointSize: root.pointSize
      font.weight: Style.fontWeightSemiBold
      color: root.isHovered && !Style.materialControls ? ShellColors.mOnHover : (root.checked ? ShellColors.mOnPrimary : ShellColors.mOnSurface)
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter

      Behavior on color {
        enabled: !ShellColors.isTransitioning
        ColorAnimation {
          duration: Style.animationFast
          easing.type: Easing.OutCubic
        }
      }
    }
  }

  // Tooltip
  Timer {
    id: tooltipTimer
    interval: 500
    onTriggered: {
      if (root.isHovered && root.tooltipText && (!Array.isArray(root.tooltipText) || root.tooltipText.length > 0)) {
        TooltipService.show(root, root.tooltipText);
      }
    }
  }

  MouseArea {
    id: tabMouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onEntered: {
      root.isHovered = true;
      if (root.tooltipText && (!Array.isArray(root.tooltipText) || root.tooltipText.length > 0)) {
        tooltipTimer.start();
      }
    }
    onExited: {
      root.isHovered = false;
      tooltipTimer.stop();
      if (root.tooltipText && (!Array.isArray(root.tooltipText) || root.tooltipText.length > 0)) {
        TooltipService.hide();
      }
    }
    onClicked: {
      root.clicked();
      // Update parent NTabBar's currentIndex
      if (root.parent && root.parent.parent && root.parent.parent.currentIndex !== undefined) {
        root.parent.parent.currentIndex = root.tabIndex;
      }
    }
  }
}
