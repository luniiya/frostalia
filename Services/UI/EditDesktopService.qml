pragma Singleton

import QtQuick
import Quickshell
import "../../Helpers/EditDesktopGeometry.js" as Geometry
import qs.Commons
import qs.Services.Compositor

// State of the Edit Desktop screen. It is open exactly while DesktopWidgetRegistry.editMode is on, so
// every way of entering edit mode (IPC, settings button, bar menu) opens the editor.
Singleton {
  id: root

  readonly property bool active: DesktopWidgetRegistry.editMode

  // 0 = the normal desktop, 1 = the desktop shrunk into the card; one number drives every piece of the animation
  property real progress: active ? 1 : 0

  Behavior on progress {
    NumberAnimation {
      duration: root.active ? Style.animationSlow : Style.animationNormal
      easing.type: Easing.OutCubic
    }
  }

  // The editor stays mapped while it animates away
  readonly property bool shown: active || progress > 0.001

  // The monitor being edited (the focused one when the mode was entered)
  property string screenName: ""

  // The selected widget on that monitor (index in its saved list), -1 for none
  property int selectedIndex: -1

  // Layout of the card, see Helpers/EditDesktopGeometry.js
  readonly property real cardPad: Math.round(60 * Style.uiScaleRatio)
  readonly property real shelfHeight: Math.round(230 * Style.uiScaleRatio)

  function cardRect(screenWidth, screenHeight) {
    return Geometry.cardRect(screenWidth, screenHeight, cardPad, shelfHeight);
  }

  onActiveChanged: {
    selectedIndex = -1;
    dragId = "";
    if (!active)
      return;
    const focused = CompositorService.getFocusedScreen();
    screenName = focused ? focused.name : (Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "");
  }

  function select(index) {
    selectedIndex = index;
  }

  // A tile being pulled off the shelf, with the pointer in window coordinates
  property string dragId: ""
  property real dragX: 0
  property real dragY: 0
  readonly property bool dragging: dragId !== ""

  function cancelDrag() {
    dragId = "";
  }

  // Esc: first cancel a pull, then drop the selection, then leave
  function back() {
    if (dragging)
      cancelDrag();
    else if (selectedIndex >= 0)
      select(-1);
    else
      DesktopWidgetRegistry.editMode = false;
  }

  // How many of a widget the edited monitor has
  function countOf(widgetId) {
    return widgetsOf(screenName).filter(w => w.id === widgetId).length;
  }

  function widgetsOf(monitorName) {
    const monitors = Settings.data.desktopWidgets.monitorWidgets || [];
    for (let i = 0; i < monitors.length; i++) {
      if (monitors[i].name === monitorName)
        return monitors[i].widgets || [];
    }
    return [];
  }

  // Everything that can be put on the desktop: core widgets, then plugin widgets
  readonly property var shelfIds: {
    const ids = Object.keys(DesktopWidgetRegistry.widgets || {});
    ids.sort((a, b) => {
               const pa = a.indexOf("plugin:") === 0;
               const pb = b.indexOf("plugin:") === 0;
               return pa === pb ? a.localeCompare(b) : (pa ? 1 : -1);
             });
    return ids;
  }

  // Put a widget on the edited monitor with its middle at a desktop point, and select it
  function addWidget(widgetId, desktopX, desktopY, screenWidth, screenHeight) {
    const data = Geometry.newWidget(widgetId, DesktopWidgetRegistry.widgetMetadata[widgetId], desktopX, desktopY, screenWidth, screenHeight);
    const monitors = (Settings.data.desktopWidgets.monitorWidgets || []).slice();
    let index = 0;
    let found = false;
    for (let i = 0; i < monitors.length; i++) {
      if (monitors[i].name === screenName) {
        const widgets = (monitors[i].widgets || []).slice();
        widgets.push(data);
        index = widgets.length - 1;
        monitors[i] = {
          "name": screenName,
          "widgets": widgets
        };
        found = true;
        break;
      }
    }
    if (!found)
      monitors.push({
                      "name": screenName,
                      "widgets": [data]
                    });
    Settings.data.desktopWidgets.monitorWidgets = monitors;
    selectedIndex = index;
    Logger.i("EditDesktop", "Added widget", widgetId, "to", screenName);
  }
}
