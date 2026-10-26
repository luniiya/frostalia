import QtQuick

// An icon from the shell's icon font, through the face kit.
Text {
  required property var kit
  property string icon: ""
  property real size: 10

  text: kit.glyph(icon)
  visible: icon !== ""
  font.family: kit.iconFamily
  font.pointSize: Math.max(1, size)
  horizontalAlignment: Text.AlignHCenter
  verticalAlignment: Text.AlignVCenter
}
