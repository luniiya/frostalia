import QtQuick
import qs.Commons

// NMaterialQuickSlider track: Android's wide filled track, split around the handle.
Item {
  id: root

  property Item control

  readonly property real split: control.visualPosition * width

  Rectangle {
    x: root.control.mirrored ? root.split + 6 * Style.uiScaleRatio : 0
    width: Math.max(0, root.control.mirrored ? root.width - x : root.split - 6 * Style.uiScaleRatio)
    height: parent.height
    radius: Math.min(Style.iRadiusS, height / 2)
    color: root.control.enabled ? root.control.fillColor : ShellColors.mOutline
  }
  Rectangle {
    x: root.control.mirrored ? 0 : root.split + 6 * Style.uiScaleRatio
    width: Math.max(0, root.control.mirrored ? root.split - 6 * Style.uiScaleRatio : root.width - x)
    height: parent.height
    radius: Math.min(Style.iRadiusS, height / 2)
    color: Qt.tint(ShellColors.mSurfaceVariant, Qt.alpha(root.control.fillColor, 0.18))
  }
}
