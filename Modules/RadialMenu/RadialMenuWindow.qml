import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services.UI

// Full-screen overlay holding the ring. Clicking outside the ring or Esc closes it;
// the center (or right click, Backspace) goes up a level.
PanelWindow {
  id: root

  color: "transparent"

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: RadialMenuService.active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  WlrLayershell.exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "frostalia-radial-menu-" + (screen?.name || "unknown")

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  // Once closing, let clicks through to whatever is below
  mask: RadialMenuService.active ? null : emptyMask
  Region {
    id: emptyMask
  }

  Item {
    id: content
    anchors.fill: parent
    focus: true

    Keys.onPressed: event => {
      if (event.key === Qt.Key_Escape) {
        RadialMenuService.close();
      } else if (event.key === Qt.Key_Backspace) {
        RadialMenuService.back();
      } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
        RadialMenuService.cycle(1);
      } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) {
        RadialMenuService.cycle(-1);
      } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
        if (RadialMenuService.hovered >= 0)
          RadialMenuService.pickIndex(RadialMenuService.hovered);
      } else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
        RadialMenuService.pickIndex(event.key - Qt.Key_1);
      } else {
        return;
      }
      event.accepted = true;
    }

    MouseArea {
      anchors.fill: parent
      enabled: RadialMenuService.active
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

      onPositionChanged: mouse => RadialMenuService.pointerMoved(mouse.x, mouse.y)
      onPressed: mouse => {
        if (mouse.button === Qt.RightButton)
          RadialMenuService.back();
        else if (mouse.button === Qt.MiddleButton)
          RadialMenuService.close();
        else
          RadialMenuService.clicked(mouse.x, mouse.y);
      }
      // Only reached if the compositor hands the opening press over to this window
      onReleased: mouse => {
        if (RadialMenuService.held)
          RadialMenuService.pointerReleased(mouse.x, mouse.y);
      }
    }

    // One ring per level; a new level re-runs the grow-in animation
    Repeater {
      model: [RadialMenuService.levelKey]

      delegate: RadialRing {
        x: RadialMenuService.center.x
        y: RadialMenuService.center.y
        items: RadialMenuService.ring
        spec: RadialMenuService.visual
        s: RadialMenuService.scale
        hovered: RadialMenuService.hovered
        held: RadialMenuService.held
        nested: RadialMenuService.path.length > 0

        Behavior on x {
          NumberAnimation {
            duration: Style.animationFast
            easing.type: Easing.OutCubic
          }
        }
        Behavior on y {
          NumberAnimation {
            duration: Style.animationFast
            easing.type: Easing.OutCubic
          }
        }

        // Closing: shrink back into the center
        opacity: RadialMenuService.progress
        scale: 0.6 + 0.4 * RadialMenuService.progress
      }
    }
  }
}
