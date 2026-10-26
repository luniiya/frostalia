pragma Singleton

import QtQuick
import Quickshell
import "../../Helpers/RadialMenu.js" as RadialMenu
import "../../Helpers/UiStyles.js" as UiStyles
import qs.Commons

// State of the desktop radial menu (right click on the empty desktop). The geometry and
// the gesture/click state machine live in Helpers/RadialMenu.js; this only feeds pointer
// events in; Modules/RadialMenu runs the picked item's action.
Singleton {
  id: root

  // Screen the menu is open on, and the pointer state machine (null when closed)
  property var screen: null
  property var menuState: null
  readonly property bool active: menuState !== null

  signal activated(var item, var screen)
  readonly property string screenName: screen ? screen.name : ""

  // 0 closed, 1 open; the window stays mapped while it animates away
  property real progress: active ? 1 : 0
  Behavior on progress {
    NumberAnimation {
      duration: root.active ? Style.animationNormal : Style.animationFast
      easing.type: Easing.OutCubic
    }
  }
  readonly property bool shown: active || progress > 0.001
  onShownChanged: {
    if (!shown)
      screen = null;
  }

  readonly property var items: RadialMenu.expandItems(RadialMenu.normalizeItems(Settings.data.radialMenu.items), UiStyles.choices())
  readonly property var visual: RadialMenu.visual(Style.uiStyleTokens.radialMenu)
  readonly property real scale: Style.uiScaleRatio

  // Current ring and where it sits; kept while closing so the ring can animate out
  property var path: []
  property var center: ({
                          "x": 0,
                          "y": 0
                        })
  property int hovered: -1
  property bool held: false
  readonly property var ring: RadialMenu.itemsAt(items, path)
  // Links back to the parent rings' centers, see RadialMenu.trail()
  property var trail: []
  // Last pointer position on the menu's screen
  property point pointer: Qt.point(0, 0)
  readonly property string levelKey: path.join("/")

  function options() {
    const v = visual;
    const outer = (v.shape === "orbit" ? v.itemRadius + v.bubbleRadius : v.outerRadius) * scale;
    const dead = v.centerRadius * scale;
    return {
      "width": screen ? screen.width : 0,
      "height": screen ? screen.height : 0,
      "deadZone": dead,
      "descendRadius": outer,
      "dragThreshold": dead * 0.5,
      "reach": outer + Math.max(v.shadowY, v.hoverLift) * scale,
      "margin": Style.marginL,
      "itemRadius": v.itemRadius * scale
    };
  }

  function apply(next) {
    menuState = next;
    if (!next)
      return;
    path = next.path;
    trail = RadialMenu.trail(next, items);
    center = next.centers[next.centers.length - 1];
    hovered = next.hovered;
    held = next.held;
  }

  function openAt(targetScreen, x, y) {
    if (!Settings.data.radialMenu.enabled || items.length === 0)
      return;
    screen = targetScreen;
    pointer = Qt.point(x, y);
    apply(RadialMenu.open(x, y, options()));
  }

  function close() {
    menuState = null;
    hovered = -1;
    held = false;
  }

  function pointerMoved(x, y) {
    pointer = Qt.point(x, y);
    if (menuState)
      apply(RadialMenu.move(menuState, x, y, items, options()));
  }

  function finish(result) {
    const pickedScreen = screen;
    if (!result.state)
      close();
    else
      apply(result.state);
    if (result.activate) {
      const item = result.activate;
      // Let the menu get out of the way before panels or the editor open
      Qt.callLater(() => root.activated(item, pickedScreen));
    }
  }

  function pointerReleased(x, y) {
    if (menuState)
      finish(RadialMenu.release(menuState, x, y, items, options()));
  }

  function clicked(x, y) {
    pointer = Qt.point(x, y);
    if (menuState)
      finish(RadialMenu.click(menuState, x, y, items, options()));
  }

  function pickIndex(index) {
    if (menuState)
      finish(RadialMenu.pick(menuState, index, items, options()));
  }

  function back() {
    if (!menuState)
      return;
    const next = RadialMenu.back(menuState);
    if (next)
      apply(next);
    else
      close();
  }

  function cycle(delta) {
    if (!menuState || ring.length === 0)
      return;
    const next = Object.assign({}, menuState);
    next.hovered = hovered < 0 ? (delta > 0 ? 0 : ring.length - 1) : (hovered + delta + ring.length) % ring.length;
    apply(next);
  }

  // ---------------------------------------------------------------------------
  // Item labels

  function appEntry(item) {
    return item && item.action === "app" && item.arg ? ThemeIcons.findAppEntry(item.arg) : null;
  }

  function labelFor(item) {
    if (!item)
      return "";
    if (item.label)
      return item.label;
    const key = RadialMenu.labelKeyFor(item);
    if (key)
      return I18n.tr(key);
    const entry = appEntry(item);
    return entry && entry.name ? entry.name : item.arg;
  }

  // Themed app icon for app items without a custom icon, else ""
  function appIconSource(item) {
    if (!item || item.icon || item.action !== "app")
      return "";
    return item.arg ? ThemeIcons.iconForAppId(item.arg) : "";
  }
}
