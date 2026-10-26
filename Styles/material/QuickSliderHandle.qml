import QtQuick
import qs.Commons

// NMaterialQuickSlider handle: a slim bar that narrows while pressed.
Item {
  id: root

  property Item control

  Rectangle {
    anchors.centerIn: parent
    width: Math.round((root.control.pressed ? 3 : 4) * Style.uiScaleRatio)
    height: parent.height
    radius: width / 2
    color: root.control.enabled ? root.control.fillColor : ShellColors.mOutline
  }
}
