import QtQuick
import qs.Commons

// Shared background for text fields, dropdowns, spin boxes and other input fields.
// Material: rounded filled field with an outline on focus.
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
  border.color: active ? activeBorderColor : ShellColors.mOutline
  border.width: fieldShape ? fieldShape.borderWidth : (outlined ? Style.borderS : 0)

  Behavior on border.color {
    ColorAnimation {
      duration: Style.animationFast
    }
  }
}
