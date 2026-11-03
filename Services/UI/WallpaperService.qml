pragma Singleton
import Qt.labs.folderlistmodel

import QtQuick
import Quickshell
import Quickshell.Io
import "../../Helpers/SystemWallpaper.js" as SystemWallpaper
import "../../Helpers/WallpaperRenderer.js" as WallpaperRenderer
import qs.Commons
import qs.Services.Power

// Which image each screen shows, for theming, the media card, the wallpaper visualizer,
// cut-outs and Edit Desktop (`getWallpaper(screenName)`). Two backends:
// - the system wallpaper daemon (default): awww/swww or hyprpaper draws the wallpaper and
//   this service polls which image it shows;
// - the shell's own renderer (Settings > Wallpaper, `wallpaperRenderer.enabled`): this
//   service picks the picture from the light or dark folder that matches the color mode,
//   pre-scales it to each screen through ImageCacheService, and Modules/Background/
//   WallpaperLayer.qml draws it with a transition. After SekaiPop's wallpaper manager
//   (github.com/Blapples/SekaiPop, GPL-3.0).
Singleton {
  id: root

  // { screenName: imagePath } as last reported by the daemon or picked by the renderer
  property var currentWallpapers: ({})
  property bool isInitialized: false

  // Emitted for each screen whose image changed
  signal wallpaperChanged(string screenName, string path)
  // Emitted after every query, changed or not (with the renderer: once a pending change is on screen)
  signal refreshed

  // awww (swww fork), swww, then hyprpaper; the first daemon that answers wins
  readonly property string queryScript: "awww query 2>/dev/null || swww query 2>/dev/null || hyprctl hyprpaper listactive 2>/dev/null"

  function init() {
    Logger.i("Wallpaper", "Service started (" + (rendererEnabled ? "shell renderer" : "system wallpaper daemon") + ")");
    started = true;
    if (rendererEnabled)
      startRenderer();
    else
      refresh();
  }

  function getWallpaper(screenName) {
    return SystemWallpaper.wallpaperFor(currentWallpapers, screenName);
  }

  function getWallpapersEffectiveMap() {
    return currentWallpapers;
  }

  // Ask the daemon again, or with the renderer wait for a pending change; `refreshed` fires when done
  function refresh() {
    if (rendererEnabled) {
      if (pendingScreens.length === 0)
        Qt.callLater(root.refreshed);
      else
        refreshWanted = true;
      return;
    }
    if (queryProcess.running) {
      queryProcess.pending = true;
      return;
    }
    queryProcess.running = true;
  }

  // -------------------------------------------------
  // Shell renderer
  // -------------------------------------------------
  readonly property var prefs: Settings.data.wallpaperRenderer
  readonly property bool rendererEnabled: prefs.enabled
  readonly property string home: Quickshell.env("HOME")
  property bool started: false
  // Parallax zooms the picture, so its copies are cut larger than the screen
  readonly property real zoom: WallpaperRenderer.parallaxZoom(prefs.parallax, prefs.parallaxAmount)

  // "" follows the shell's color mode; "light" or "dark" when set over IPC (`wallpaper mode`)
  property string modeOverride: ""
  readonly property string mode: WallpaperRenderer.modeFor(Settings.data.colorSchemes.darkMode, modeOverride)
  readonly property string lightFolder: WallpaperRenderer.folderFor("light", prefs, home)
  readonly property string darkFolder: WallpaperRenderer.folderFor("dark", prefs, home)
  readonly property string folder: mode === "dark" ? darkFolder : lightFolder

  // Sorted image paths of each folder, and of the one in use
  property var lightImages: []
  property var darkImages: []
  property bool lightListed: false
  property bool darkListed: false
  readonly property var images: mode === "dark" ? darkImages : lightImages
  readonly property bool listed: mode === "dark" ? darkListed : lightListed

  // The picture on screen (the original file) and, per screen, the pre-scaled copy that
  // WallpaperLayer draws: { screenName: file }
  property string rendererPath: ""
  property var displayPaths: ({})
  // Screens still waiting for their copy of rendererPath
  property var pendingScreens: []
  property bool refreshWanted: false
  property int applyToken: 0

  // The random pick after this one, rolled ahead so it is pre-scaled when it's asked for
  property string upcomingRandom: ""

  // Transition style of the last change; screens switching together share it
  property string lastStyle: ""
  property double styleRolledAt: 0

  function displayPathFor(screenName) {
    return displayPaths[screenName] || "";
  }

  // The style a change that starts now plays. Screens that switch within a moment of each
  // other get the same pick, so one change plays one transition everywhere.
  function styleForSwitch() {
    const now = Date.now();
    if (now - styleRolledAt > 400) {
      lastStyle = WallpaperRenderer.styleForSwitch(prefs.transition, lastStyle);
      styleRolledAt = now;
    }
    return lastStyle;
  }

  // Public API (IPC): show a picture, step through the folder or roll a random one
  // `forMode`: the mode to remember it for ("light" or "dark"), so a color mode switch
  // that follows keeps it; by default its folder's mode, else the current one
  function setWallpaper(path, forMode) {
    const p = WallpaperRenderer.expandHome(path, home);
    if (!rendererEnabled || !p)
      return;
    showPicture(p, WallpaperRenderer.modeForPicture(p, forMode, prefs, home, mode));
  }

  function next() {
    if (rendererEnabled)
      showPicture(WallpaperRenderer.step(images, rendererPath, 1), mode);
  }

  function previous() {
    if (rendererEnabled)
      showPicture(WallpaperRenderer.step(images, rendererPath, -1), mode);
  }

  function random() {
    if (!rendererEnabled)
      return;
    const pick = images.indexOf(upcomingRandom) >= 0 && upcomingRandom !== rendererPath ? upcomingRandom : WallpaperRenderer.pickRandom(images, [rendererPath]);
    showPicture(pick, mode);
  }

  // "light", "dark" or "auto" (follow the shell's color mode); false when not understood
  function setMode(arg) {
    const m = WallpaperRenderer.normalizeMode(arg);
    if (m === "")
      return false;
    modeOverride = m === "auto" ? "" : m;
    return true;
  }

  function showPicture(path, forMode, list) {
    if (!path)
      return;
    if (forMode === "light" || forMode === "dark")
      remember(forMode, path);
    if (path === rendererPath && pendingScreens.length === 0)
      return;
    rendererPath = path;
    upcomingRandom = WallpaperRenderer.pickRandom(list || images, [path]);
    Logger.d("Wallpaper", "Renderer shows", path);
    publish(path);
    runChangeHook(path, forMode === "light" || forMode === "dark" ? forMode : mode);
    resolveDisplays();
    precacheTimer.restart();
  }

  // The picture on screen, for tools outside the shell: the lock screen draws
  // `<cache>/wallpaper/current.png`, and pickers read where `current` links to
  readonly property string publishDir: Settings.cacheDir + "wallpaper"
  property string publishWanted: ""

  function publish(path) {
    publishWanted = path;
    if (!publishProcess.running)
      publishProcess.start(path);
  }

  // wallpaperRenderer.changeCommand, one at a time; a picture shown while it runs gets
  // its turn after it
  property var changeHookWanted: null

  function runChangeHook(path, forMode) {
    changeHookWanted = WallpaperRenderer.changeHook(prefs.changeCommand, path, forMode);
    if (changeHookWanted && !changeHookProcess.running)
      changeHookProcess.startWanted();
  }

  // The picture last shown for a mode ("" if none)
  function rememberedFor(forMode) {
    return ShellState.getWallpaperRendererState()[forMode] || "";
  }

  function remember(forMode, path) {
    const state = Object.assign({}, ShellState.getWallpaperRendererState());
    if (state[forMode] === path)
      return;
    state[forMode] = path;
    ShellState.setWallpaperRendererState(state);
  }

  // Ask for each screen's copy of rendererPath; a screen switches once its copy is ready
  function resolveDisplays() {
    if (!rendererPath || !ImageCacheService.initialized)
      return;
    const token = ++applyToken;
    const path = rendererPath;
    const screens = Quickshell.screens.slice();
    pendingScreens = screens.map(s => s.name);
    for (const screen of screens) {
      const name = screen.name;
      const size = WallpaperRenderer.cacheSize(screen.width, screen.height, screen.devicePixelRatio, zoom);
      ImageCacheService.getScreenWallpaper(path, size.width, size.height, function (cached) {
        if (token !== root.applyToken)
          return;
        root.screenReady(name, cached || path, path);
      });
    }
  }

  function screenReady(name, file, path) {
    const shown = Object.assign({}, displayPaths);
    shown[name] = file;
    displayPaths = shown;
    pendingScreens = pendingScreens.filter(s => s !== name);
    if (currentWallpapers[name] !== path) {
      const map = Object.assign({}, currentWallpapers);
      map[name] = path;
      currentWallpapers = map;
      wallpaperChanged(name, path);
    }
    if (pendingScreens.length === 0 && refreshWanted) {
      refreshWanted = false;
      refreshed();
    }
  }

  // The mode's folder has been listed or changed: show what it showed last, or a random one
  // Reads the mode's own lists rather than `images` and `listed`: onModeChanged can run
  // before those bindings have followed the new mode
  function pickForMode() {
    const m = WallpaperRenderer.modeFor(Settings.data.colorSchemes.darkMode, modeOverride);
    const list = m === "dark" ? darkImages : lightImages;
    if (!rendererEnabled || !started || !(m === "dark" ? darkListed : lightListed))
      return;
    if (list.length === 0) {
      Logger.w("Wallpaper", "No images in", (m === "dark" ? darkFolder : lightFolder) || "(no folder set)");
      return;
    }
    const remembered = ShellState.getWallpaperRendererState()[m];
    showPicture(WallpaperRenderer.startingPicture(list, remembered, undefined, rendererPath), m, list);
  }

  function startRenderer() {
    isInitialized = true;
    currentWallpapers = ({});
    displayPaths = ({});
    rendererPath = "";
    pickForMode();
  }

  // Back to the daemon: forget the renderer's picture and ask the daemon what it shows.
  // Still initialized, so the daemon's pictures arrive as changes and theming follows.
  function stopRenderer() {
    applyToken++;
    pendingScreens = [];
    rendererPath = "";
    displayPaths = ({});
    currentWallpapers = ({});
    precacheQueue = [];
    isInitialized = true;
    refresh();
  }

  onRendererEnabledChanged: {
    if (!started)
      return;
    Logger.i("Wallpaper", rendererEnabled ? "Switched to the shell renderer" : "Switched to the system wallpaper daemon");
    if (rendererEnabled)
      startRenderer();
    else
      stopRenderer();
  }
  onModeChanged: pickForMode()
  onListedChanged: pickForMode()
  // Parallax turned on or off, or its amount changed: cut the copies to the new size
  onZoomChanged: {
    if (!rendererEnabled || !started)
      return;
    resolveDisplays();
    precacheTimer.restart();
  }

  // ImageCacheService starts after this service; a picture picked before it knew about
  // ImageMagick is resolved once it does
  Connections {
    target: ImageCacheService
    function onInitializedChanged() {
      if (root.rendererEnabled && ImageCacheService.initialized)
        root.resolveDisplays();
    }
  }

  Connections {
    target: Quickshell
    function onScreensChanged() {
      if (root.rendererEnabled)
        root.resolveDisplays();
    }
  }

  function folderUrl(path) {
    return path ? "file://" + path.split("/").map(encodeURIComponent).join("/") : "";
  }

  function collect(model) {
    const paths = [];
    for (let i = 0; i < model.count; i++)
      paths.push(model.get(i, "filePath"));
    return WallpaperRenderer.sortedImages(paths);
  }

  FolderListModel {
    id: lightModel
    folder: root.rendererEnabled ? root.folderUrl(root.lightFolder) : ""
    nameFilters: WallpaperRenderer.imageExtensions.map(e => "*." + e)
    caseSensitive: false
    showDirs: false
    onFolderChanged: root.lightListed = false
    onStatusChanged: lightScan.restart()
    onCountChanged: lightScan.restart()
  }

  FolderListModel {
    id: darkModel
    folder: root.rendererEnabled ? root.folderUrl(root.darkFolder) : ""
    nameFilters: WallpaperRenderer.imageExtensions.map(e => "*." + e)
    caseSensitive: false
    showDirs: false
    onFolderChanged: root.darkListed = false
    onStatusChanged: darkScan.restart()
    onCountChanged: darkScan.restart()
  }

  // The models fill in bursts; read them once they've settled
  Timer {
    id: lightScan
    interval: 150
    onTriggered: {
      if (lightModel.status !== FolderListModel.Ready)
        return;
      root.lightImages = root.collect(lightModel);
      root.lightListed = true;
      precacheTimer.restart();
    }
  }

  Timer {
    id: darkScan
    interval: 150
    onTriggered: {
      if (darkModel.status !== FolderListModel.Ready)
        return;
      root.darkImages = root.collect(darkModel);
      root.darkListed = true;
      precacheTimer.restart();
    }
  }

  // A random wallpaper every N minutes (Settings > Wallpaper)
  Timer {
    interval: Math.max(60000, WallpaperRenderer.intervalMs(root.prefs.randomEnabled, root.prefs.randomMinutes))
    running: root.rendererEnabled && root.started && root.prefs.randomEnabled
    repeat: true
    onTriggered: root.random()
  }

  // Pre-scaling ahead of time: the next pictures first, then both folders, one at a time
  // and at the lowest CPU priority, paused in eco mode. Cached copies are only checked.
  property var precacheQueue: []
  property bool precaching: false
  // "Cache all wallpapers now": both folders, now, even with pre-scaling off or in eco mode
  property bool cachingAll: false
  property int cacheAllTotal: 0
  readonly property int cacheAllDone: cachingAll ? cacheAllTotal - precacheQueue.length : 0
  signal cacheAllFinished

  // false when ImageMagick is missing
  function cacheAll() {
    if (!ImageCacheService.imageMagickAvailable)
      return false;
    const other = mode === "dark" ? lightImages : darkImages;
    precacheQueue = WallpaperRenderer.cacheAllOrder(images, other);
    cacheAllTotal = precacheQueue.length;
    cachingAll = true;
    if (!precaching)
      precacheNext();
    return true;
  }

  Timer {
    id: precacheTimer
    interval: 5000
    onTriggered: root.startPrecache()
  }

  function startPrecache() {
    if (cachingAll || !rendererEnabled || !prefs.precache || !ImageCacheService.imageMagickAvailable)
      return;
    const other = mode === "dark" ? lightImages : darkImages;
    const otherMode = mode === "dark" ? "light" : "dark";
    const upcoming = [upcomingRandom, WallpaperRenderer.step(images, rendererPath, 1), WallpaperRenderer.step(images, rendererPath, -1)];
    const first = WallpaperRenderer.precacheOrder(images, rendererPath, upcoming);
    const rest = WallpaperRenderer.precacheOrder(other, "", [ShellState.getWallpaperRendererState()[otherMode]]);
    precacheQueue = first.concat(rest.filter(p => first.indexOf(p) < 0));
    if (!precaching)
      precacheNext();
  }

  function precacheNext() {
    if (precacheQueue.length === 0 || !rendererEnabled || (!cachingAll && (!prefs.precache || PowerProfileService.ecoMode))) {
      precaching = false;
      if (cachingAll && precacheQueue.length === 0) {
        cachingAll = false;
        cacheAllFinished();
      }
      return;
    }
    precaching = true;
    const path = precacheQueue[0];
    precacheQueue = precacheQueue.slice(1);
    const screens = Quickshell.screens.slice();
    let left = screens.length;
    if (left === 0) {
      precaching = false;
      return;
    }
    for (const screen of screens) {
      const size = WallpaperRenderer.cacheSize(screen.width, screen.height, screen.devicePixelRatio, zoom);
      ImageCacheService.getScreenWallpaper(path, size.width, size.height, function () {
        if (--left === 0)
          Qt.callLater(root.precacheNext);
      }, true);
    }
  }

  Connections {
    target: PowerProfileService
    function onEcoModeChanged() {
      if (!PowerProfileService.ecoMode && root.precacheQueue.length > 0 && !root.precaching)
        root.precacheNext();
    }
  }

  // -------------------------------------------------
  // System wallpaper daemon
  // -------------------------------------------------

  // Wallpaper tools don't notify anyone, so poll; a query is a single socket round trip
  Timer {
    interval: 3000
    repeat: true
    running: root.isInitialized && !root.rendererEnabled
    onTriggered: root.refresh()
  }

  // One at a time; a picture picked while one is written is published after it
  Process {
    id: publishProcess
    property string path: ""
    function start(p) {
      path = p;
      command = ["sh", "-c", WallpaperRenderer.publishCommand(p, root.publishDir)];
      running = true;
    }
    onExited: exitCode => {
      if (exitCode !== 0)
        Logger.w("Wallpaper", "Could not publish", path, "to", root.publishDir);
      if (root.publishWanted !== path)
        start(root.publishWanted);
    }
  }

  Process {
    id: changeHookProcess
    function startWanted() {
      const hook = root.changeHookWanted;
      root.changeHookWanted = null;
      environment = hook.environment;
      command = hook.command;
      running = true;
    }
    stderr: StdioCollector {
      id: changeHookErr
    }
    onExited: exitCode => {
      if (exitCode !== 0)
        Logger.w("Wallpaper", "Change command failed:", exitCode, changeHookErr.text.trim());
      if (root.changeHookWanted)
        startWanted();
    }
  }

  Process {
    id: queryProcess
    property bool pending: false
    command: ["sh", "-c", root.queryScript]
    stdout: StdioCollector {
      id: queryOutput
    }
    onExited: {
      // The renderer was switched on while the query ran
      if (root.rendererEnabled) {
        pending = false;
        return;
      }
      const parsed = SystemWallpaper.parseQuery(queryOutput.text);
      // The first query is the starting state, not a change
      const changed = root.isInitialized ? SystemWallpaper.changedScreens(root.currentWallpapers, parsed) : [];
      root.currentWallpapers = parsed;
      if (!root.isInitialized) {
        root.isInitialized = true;
        if (Object.keys(parsed).length === 0)
          Logger.w("Wallpaper", "No wallpaper daemon answered (awww, swww or hyprpaper)");
      }
      for (const screen of changed) {
        Logger.d("Wallpaper", "Wallpaper on", screen, "is now", parsed[screen]);
        root.wallpaperChanged(screen, parsed[screen]);
      }
      root.refreshed();
      if (pending) {
        pending = false;
        running = true;
      }
    }
  }
}
