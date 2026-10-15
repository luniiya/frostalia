pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../../Helpers/SystemWallpaper.js" as SystemWallpaper
import qs.Commons

// The shell doesn't draw wallpapers; the system wallpaper daemon does. This service only
// tracks which image each screen shows, for theming and the media card.
Singleton {
  id: root

  // { screenName: imagePath } as last reported by the daemon
  property var currentWallpapers: ({})
  property bool isInitialized: false

  // Emitted for each screen whose image changed
  signal wallpaperChanged(string screenName, string path)
  // Emitted after every query, changed or not
  signal refreshed

  // awww (swww fork), swww, then hyprpaper; the first daemon that answers wins
  readonly property string queryScript: "awww query 2>/dev/null || swww query 2>/dev/null || hyprctl hyprpaper listactive 2>/dev/null"

  function init() {
    Logger.i("Wallpaper", "Service started (system wallpaper daemon)");
    refresh();
  }

  function getWallpaper(screenName) {
    return SystemWallpaper.wallpaperFor(currentWallpapers, screenName);
  }

  function getWallpapersEffectiveMap() {
    return currentWallpapers;
  }

  // Ask the daemon again; `refreshed` fires when done
  function refresh() {
    if (queryProcess.running) {
      queryProcess.pending = true;
      return;
    }
    queryProcess.running = true;
  }

  // Wallpaper tools don't notify anyone, so poll; a query is a single socket round trip
  Timer {
    interval: 3000
    repeat: true
    running: root.isInitialized
    onTriggered: root.refresh()
  }

  Process {
    id: queryProcess
    property bool pending: false
    command: ["sh", "-c", root.queryScript]
    stdout: StdioCollector {
      id: queryOutput
    }
    onExited: {
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
