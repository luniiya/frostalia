import QtQuick
import qs.Commons

// Shared background for text fields, dropdowns, spin boxes and other input fields,
// drawn by the style's Field skin (Styles/<style>/Field.qml).
Item {
  id: root

  property bool active: false
  property bool hovered: false
  property bool outlined: true
  property real cornerRadius: Style.iRadiusM
  property color fillColor: ShellColors.mSurface
  property color activeBorderColor: ShellColors.mSecondary

  readonly property var fieldShape: Style.getFieldShape(active, cornerRadius)
  readonly property real radius: fieldShape ? fieldShape.radius : cornerRadius

  NStyleSkin {
    name: "Field"
    control: root
  }
}
