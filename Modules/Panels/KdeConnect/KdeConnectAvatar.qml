import QtQuick
import "../../../Helpers/KdeConnect.js" as KdeConnect
import qs.Commons
import qs.Widgets

// Contact photo, or initials on a tonal circle.
Item {
  id: root
  property string name: ""
  property string photo: ""
  property real size: Math.round(40 * Style.uiScaleRatio)
  readonly property string letters: KdeConnect.initials(name)

  implicitWidth: size
  implicitHeight: size

  Rectangle {
    anchors.fill: parent
    visible: root.photo === ""
    radius: width / 2
    color: Qt.tint(Color.mSurfaceVariant, Qt.alpha(Color.mSecondary, 0.35))
    NText {
      anchors.centerIn: parent
      visible: root.letters !== "" && root.letters !== "#"
      text: root.letters
      pointSize: root.size * 0.3
      applyUiScale: false
      font.weight: Style.fontWeightSemiBold
      color: Color.mOnSurface
    }
    NIcon {
      anchors.centerIn: parent
      visible: root.letters === "" || root.letters === "#"
      icon: "user"
      pointSize: root.size * 0.35
      applyUiScale: false
      color: Color.mOnSurface
    }
  }

  NImageRounded {
    anchors.fill: parent
    visible: root.photo !== ""
    radius: width / 2
    imagePath: root.photo
  }
}
