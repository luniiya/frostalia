import QtQuick
import QtQuick.Controls
import "../Helpers/ScrollbarStyle.js" as ScrollbarStyle
import qs.Commons

ScrollBar {
  opacity: ScrollbarStyle.opacity(hovered, pressed)

  Behavior on opacity {
    NumberAnimation {
      duration: Style.animationFast
    }
  }
}
