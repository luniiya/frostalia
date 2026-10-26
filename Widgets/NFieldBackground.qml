import QtQuick
import qs.Commons

// Shared background for text fields, dropdowns, spin boxes and other input fields.
// Material: rounded filled field with an outline on focus.
// Keycap: ink outline on a short hard shadow.
// Other styles: outlined rounded field.
Rectangle {
  id: root

  property bool active: false
  property bool hovered: false
  property bool outlined: true
  property real cornerRadius: Style.iRadiusM
  property color fillColor: ShellColors.mSurface
  property color activeBorderColor: ShellColors.mSecondary

  readonly property var fieldShape: Style.getFieldShape(active, cornerRadius)

  radius: fieldShape ? fieldShape.radius : cornerRadius
  color: fieldShape ? (hovered && !active ? Qt.alpha(ShellColors.mOnSurface, 0.12) : ShellColors.mTonalContainer) : fillColor
  border.color: active ? activeBorderColor : (Style.keycapControls ? KeycapKit.ink : ShellColors.mOutline)
  border.width: fieldShape ? fieldShape.borderWidth : (Style.keycapControls ? Style.keycapOutline : (outlined ? Style.borderS : 0))

  // Keycap: fields sit on a short hard shadow
  Rectangle {
    visible: Style.keycapControls
    z: -1
    width: parent.width
    height: parent.height
    y: Math.max(1, Style.keycapDepth - 1)
    radius: parent.radius
    color: KeycapKit.ink
  }

  Behavior on border.color {
    ColorAnimation {
      duration: Style.animationFast
    }
  }
}
