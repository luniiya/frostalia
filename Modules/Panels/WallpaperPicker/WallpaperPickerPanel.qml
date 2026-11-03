import QtQuick
import Quickshell
import "../../../Helpers/WallpaperPicker.js" as WallpaperPicker
import "../../../Helpers/WallpaperRenderer.js" as WallpaperRenderer
import qs.Commons
import qs.Modules.MainScreen
import qs.Services.UI
import qs.Widgets

// Wallpaper picker: a fullscreen coverflow of the wallpaper folder with search,
// color filters and sorting. The UI style draws it (views.wallpaperPicker); the
// view reads this panel's state and calls select(), activate(), setFamily(),
// setSort(), clearQuery() and close(). Typing goes to the search, Left/Right
// browse, Up/Down change the color filter, Tab the order, Ctrl+L / Ctrl+D the
// light or dark folder, Enter sets the wallpaper (and that color mode). Wallpapers come from WallpaperPickerService.
SmartPanel {
  id: root

  preferredWidthRatio: 1.0
  preferredHeightRatio: 1.0
  panelBackgroundColor: "transparent"
  blurEnabled: false
  // The whole screen dims and blurs a little, so the wallpapers stand out
  dimmerOpacity: 0.3
  blurScreen: true
  // The views animate the opening themselves (intro)
  ownAnimation: true
  panelAnchorHorizontalCenter: true
  panelAnchorVerticalCenter: true

  // Which folder is browsed, "light" or "dark"; opens on the current color mode
  property string pickMode: "dark"
  property string query: ""
  property string familyKey: ""
  property string sortBy: Settings.data.wallpaperPicker.sortBy
  property int selectedIndex: -1
  property string selectedPath: ""

  readonly property var allEntries: WallpaperPickerService.entries.filter(e => WallpaperRenderer.modeOfPath(e.path, Settings.data.wallpaperRenderer, WallpaperPickerService.home) === pickMode)
  readonly property var entries: WallpaperPicker.filtered(allEntries, query, familyKey, sortBy)
  readonly property var selectedEntry: selectedIndex >= 0 && selectedIndex < entries.length ? entries[selectedIndex] : null
  // Matches per color under the current search, for the swatch badges
  readonly property var familyCounts: WallpaperPicker.familyCounts(allEntries.filter(e => WallpaperPicker.matches(e.name, query)))
  readonly property int totalCount: allEntries.length
  readonly property bool loading: !WallpaperPickerService.loaded
  readonly property bool indexing: WallpaperPickerService.indexing
  readonly property int indexedCount: WallpaperPickerService.indexedCount
  readonly property string folder: pickMode === "dark" ? WallpaperService.darkFolder : WallpaperService.lightFolder
  // Opening animation, 0..1, for the views (WallpaperPicker.introCard, introBar, introItem)
  property real intro: 1
  // Settled for screenshots once the list is in and the intro ran (Helpers/PanelSettle.js)
  readonly property bool contentReady: WallpaperPickerService.loaded && intro >= 1

  // Keep the selection on the same image while the list is filtered or recolored
  onEntriesChanged: {
    const index = WallpaperPicker.keepSelection(entries, selectedPath, selectedIndex);
    selectedIndex = index;
    selectedPath = index >= 0 ? entries[index].path : "";
  }

  function select(index) {
    if (index < 0 || index >= entries.length)
      return;
    selectedIndex = index;
    selectedPath = entries[index].path;
  }

  function move(delta) {
    select(WallpaperPicker.step(selectedIndex, delta, entries.length));
  }

  // A click selects a strip and sets the selected card
  function activate(index) {
    if (index === selectedIndex)
      apply();
    else
      select(index);
  }

  // Sets the wallpaper for the browsed mode, then switches the color mode to it; the
  // renderer then keeps the picture, since it is what that mode remembers
  function apply() {
    if (!selectedEntry)
      return;
    WallpaperPickerService.apply(selectedEntry.path, pickMode);
    if (WallpaperService.modeOverride === "")
      Settings.data.colorSchemes.darkMode = pickMode === "dark";
    close();
  }

  // Browse the other folder, on the picture that mode shows or remembers
  function setPickMode(mode) {
    if (mode !== "light" && mode !== "dark" || mode === pickMode)
      return;
    pickMode = mode;
    query = "";
    familyKey = "";
    selectedPath = WallpaperService.mode === mode ? WallpaperService.getWallpaper(screen ? screen.name : "") : WallpaperService.rememberedFor(mode);
    selectedIndex = WallpaperPicker.keepSelection(entries, selectedPath, 0);
  }

  function setFamily(key) {
    familyKey = key === familyKey ? "" : key;
  }

  function setSort(mode) {
    sortBy = mode;
    Settings.data.wallpaperPicker.sortBy = mode;
  }

  function clearQuery() {
    query = "";
  }

  NumberAnimation {
    id: introAnimation
    target: root
    property: "intro"
    from: 0
    to: 1
    duration: Style.animationSlow * 2
  }

  // Open on the current wallpaper, with a fresh list
  onOpened: {
    intro = 0;
    introAnimation.restart();
    pickMode = WallpaperService.mode;
    query = "";
    familyKey = "";
    selectedPath = WallpaperService.getWallpaper(screen ? screen.name : "");
    selectedIndex = WallpaperPicker.keepSelection(entries, selectedPath, 0);
    WallpaperPickerService.refresh();
  }

  function onEscapePressed() {
    if (query !== "")
      clearQuery();
    else
      close();
  }
  function onLeftPressed() {
    move(-1);
  }
  function onRightPressed() {
    move(1);
  }
  function onUpPressed() {
    familyKey = WallpaperPicker.nextFamily(familyKey, -1);
  }
  function onDownPressed() {
    familyKey = WallpaperPicker.nextFamily(familyKey, 1);
  }
  function onTabPressed() {
    setSort(WallpaperPicker.nextSort(sortBy, 1));
  }
  function onBackTabPressed() {
    setSort(WallpaperPicker.nextSort(sortBy, -1));
  }
  function onEnterPressed() {
    apply();
  }
  function onHomePressed() {
    select(0);
  }
  function onEndPressed() {
    select(entries.length - 1);
  }
  function onPageUpPressed() {
    move(-10);
  }
  function onPageDownPressed() {
    move(10);
  }

  panelContent: Item {
    id: panelContent
    focus: true

    readonly property var contentPreferredWidth: root.screen?.width || root.width || 0
    readonly property var contentPreferredHeight: root.screen?.height || root.height || 0

    Connections {
      target: root
      function onOpened() {
        Qt.callLater(() => panelContent.forceActiveFocus());
      }
    }

    // Navigation keys arrive through MainScreen's shortcuts; the rest types into the search
    Keys.onPressed: event => {
      if ((event.modifiers & Qt.ControlModifier) && (event.key === Qt.Key_L || event.key === Qt.Key_D)) {
        root.setPickMode(event.key === Qt.Key_L ? "light" : "dark");
        event.accepted = true;
      } else if (event.key === Qt.Key_Backspace) {
        root.query = WallpaperPicker.backspace(root.query, (event.modifiers & Qt.ControlModifier) !== 0);
        event.accepted = true;
      } else if ((event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)) === 0 && WallpaperPicker.typable(event.text)) {
        root.query += event.text;
        event.accepted = true;
      }
    }

    // Clicks outside the picker close it
    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
      onClicked: root.close()
    }

    NStyleView {
      anchors.fill: parent
      surface: "wallpaperPicker"
      viewProperties: ({
                         "picker": root
                       })
    }
  }
}
