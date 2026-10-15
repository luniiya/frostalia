import QtQuick
import QtQuick.Controls
import qs.Commons

// Wide, filled Android track with an end icon and a slim separated handle.
Slider {
  id: root
  property string icon: "volume-high"
  property string label: ""
  property color fillColor: Color.mPrimary
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
    Rectangle {
      x: root.mirrored ? parent.split + 6 * Style.uiScaleRatio : 0
      width: Math.max(0, root.mirrored ? parent.width - x : parent.split - 6 * Style.uiScaleRatio)
      height: parent.height
      radius: Math.min(Style.iRadiusS, height / 2)
      color: root.enabled ? root.fillColor : Color.mOutline
    }
    Rectangle {
      x: root.mirrored ? 0 : parent.split + 6 * Style.uiScaleRatio
      width: Math.max(0, root.mirrored ? parent.split - 6 * Style.uiScaleRatio : parent.width - x)
      height: parent.height
      radius: Math.min(Style.iRadiusS, height / 2)
      color: Qt.tint(Color.mSurfaceVariant, Qt.alpha(root.fillColor, 0.18))
    }
    NIcon {
      anchors.right: parent.right
      anchors.rightMargin: Math.round(12 * Style.uiScaleRatio)
      anchors.verticalCenter: parent.verticalCenter
      icon: root.icon
      color: root.visualPosition > 0.92 ? Color.mOnPrimary : Color.mOnSurfaceVariant
      pointSize: Style.fontSizeL
    }
  }

  handle: Rectangle {
    x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
    y: (root.height - height) / 2
    width: Math.round((root.pressed ? 3 : 4) * Style.uiScaleRatio)
    height: root.height - Math.round(2 * Style.uiScaleRatio)
    radius: width / 2
    color: root.enabled ? root.fillColor : Color.mOutline
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

  ToolTip.visible: root.hovered || root.pressed
  ToolTip.text: root.label + " · " + Math.round(root.value * 100) + "%"
  ToolTip.delay: 400
}
