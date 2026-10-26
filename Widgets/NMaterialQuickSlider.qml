import QtQuick
import QtQuick.Controls
import qs.Commons

// Wide filled track with an end icon. The style draws track and handle
// (Styles/<style>/QuickSliderTrack.qml, QuickSliderHandle.qml).
Slider {
  id: root
  property string icon: "volume-high"
  property string label: ""
  property color fillColor: ShellColors.mPrimary
  property real wheelStep: 0.01
  signal iconClicked

  implicitHeight: Math.round(44 * Style.uiScaleRatio)
  implicitWidth: Math.round(240 * Style.uiScaleRatio)
  leftPadding: 0
  rightPadding: 0
  topPadding: Math.round(5 * Style.uiScaleRatio)
  bottomPadding: topPadding
  stepSize: 0.01
  focusPolicy: Qt.StrongFocus
  Accessible.name: label
  Accessible.role: Accessible.Slider

  background: Item {
    x: root.leftPadding
    y: root.topPadding
    width: root.availableWidth
    height: root.availableHeight
    readonly property real split: root.visualPosition * width

    NStyleSkin {
      name: "QuickSliderTrack"
      control: root
    }
    NIcon {
      anchors.right: parent.right
      anchors.rightMargin: Math.round(12 * Style.uiScaleRatio)
      anchors.verticalCenter: parent.verticalCenter
      icon: root.icon
      color: root.visualPosition > 0.92 ? ShellColors.mOnPrimary : ShellColors.mOnSurfaceVariant
      pointSize: Style.fontSizeL
    }
  }

  handle: Item {
    x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
    y: (root.height - height) / 2
    implicitWidth: Math.round(4 * Style.uiScaleRatio)
    implicitHeight: root.height - Math.round(2 * Style.uiScaleRatio)

    NStyleSkin {
      name: "QuickSliderHandle"
      control: root
    }
  }

  // Wheel changes use the same moved signal as drag and keyboard edits.
  WheelHandler {
    target: null
    onWheel: event => {
      const delta = event.angleDelta.y || event.angleDelta.x;
      if (!root.enabled || !delta)
        return;
      root.value = Math.max(root.from, Math.min(root.to, root.value + (delta > 0 ? root.wheelStep : -root.wheelStep)));
      root.moved();
      event.accepted = true;
    }
  }

  TapHandler {
    acceptedButtons: Qt.RightButton
    onTapped: root.iconClicked()
  }
}
