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
  property color fillColor: Color.mSurface
  property color activeBorderColor: Color.mSecondary

  readonly property var fieldShape: Style.getFieldShape(active, cornerRadius)

  radius: fieldShape ? fieldShape.radius : cornerRadius
  color: fieldShape ? (hovered && !active ? Qt.alpha(Color.mOnSurface, 0.12) : Color.mTonalContainer) : fillColor
  border.color: active ? activeBorderColor : Color.mOutline
  border.width: fieldShape ? fieldShape.borderWidth : (outlined ? Style.borderS : 0)

  Behavior on border.color {
    ColorAnimation {
      duration: Style.animationFast
    }
  }
}
