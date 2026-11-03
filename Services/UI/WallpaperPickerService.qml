pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../../Helpers/WallpaperPicker.js" as WallpaperPicker
import "../../Helpers/WallpaperRenderer.js" as WallpaperRenderer
import qs.Commons

// Wallpapers for the picker (Modules/Panels/WallpaperPicker). The theming helper
// (Tools/theming, `wallpapers` command) lists the images in the renderer's light and dark
// folders and caches a thumbnail and dominant color for each; the list shows at once and
// colors fill in while the helper indexes new images. Setting a wallpaper hands it to the
// shell's renderer (WallpaperService), or runs wallpaperPicker.applyCommand when it is off.
Singleton {
  id: root

  readonly property string helper: Quickshell.env("FROSTALIA_THEMING_HELPER") || (Quickshell.shellDir + "/Tools/theming/target/release/frostalia-theming")
  readonly property string cacheDir: Settings.cacheDir + "wallpaper-picker"
  readonly property string home: Quickshell.env("HOME") || ""
  readonly property var directories: [WallpaperRenderer.folderFor("light", Settings.data.wallpaperRenderer, home), WallpaperRenderer.folderFor("dark", Settings.data.wallpaperRenderer, home)].filter((d, i, all) => d && all.indexOf(d) === i)

  // [{ path, name, ext, mtime, color, thumb }], sorted by path
  property var entries: []
  property bool loaded: false
  // True while the helper computes thumbnails and colors of new images
  property bool indexing: false
  property int indexedCount: 0

  signal applied(string path)

  property var _updates: []

  // Lists the folder again (fast, from the cache) and indexes new images
  function refresh() {
    if (scanProcess.running) {
      scanProcess.again = true;
      return;
    }
    scanProcess.start(directories, true);
  }

  // Shows path with the shell's renderer (remembered for its folder's mode), or runs
  // `wallpaperPicker.applyCommand` with $WALLPAPER when the renderer is off
  // `forMode`: the color mode ("light" or "dark") the renderer remembers it for
  function apply(path, forMode) {
    if (!path)
      return;
    Logger.i("WallpaperPicker", "Setting wallpaper", path);
    if (WallpaperService.rendererEnabled) {
      WallpaperService.setWallpaper(path, forMode);
      root.applied(path);
      return;
    }
    applyProcess.target = path;
    applyProcess.environment = {
      "WALLPAPER": path
    };
    applyProcess.command = ["sh", "-c", Settings.data.wallpaperPicker.applyCommand];
    applyProcess.running = true;
  }

  function _flushUpdates() {
    if (_updates.length === 0)
      return;
    entries = WallpaperPicker.applyUpdates(entries, _updates);
    _updates = [];
  }

  function _handleLine(line) {
    let message;
    try {
      message = JSON.parse(line);
    } catch (e) {
      Logger.w("WallpaperPicker", "Bad helper output:", String(line).slice(0, 200));
      return;
    }
    if (message.entries) {
      entries = message.entries;
      loaded = true;
      indexing = true;
      indexedCount = 0;
    } else if (message.update) {
      _updates.push(message.update);
      indexedCount++;
      if (!flushTimer.running)
        flushTimer.start();
    } else if (message.done) {
      _flushUpdates();
      indexing = false;
      if (message.indexed > 0 || message.failed > 0)
        Logger.i("WallpaperPicker", "Indexed", message.indexed, "wallpapers,", message.failed, "failed");
    }
  }

  // Applies color updates in batches, so the picker re-filters a few times a second
  Timer {
    id: flushTimer
    interval: 400
    onTriggered: root._flushUpdates()
  }

  Process {
    id: scanProcess
    property bool again: false

    function start(directories, index) {
      environment = {
        "REQUEST": JSON.stringify({
                                    "directories": directories,
                                    "cache_dir": root.cacheDir,
                                    "index": index
                                  }),
        "HELPER": root.helper
      };
      running = true;
    }

    // Low priority: indexing a large folder decodes every image once
    command: ["sh", "-c", "printf '%s' \"$REQUEST\" | exec nice -n 10 \"$HELPER\" wallpapers"]
    stdout: SplitParser {
      onRead: line => root._handleLine(line)
    }
    stderr: SplitParser {
      onRead: line => Logger.d("WallpaperPicker", line)
    }
    onExited: exitCode => {
      root._flushUpdates();
      root.indexing = false;
      if (exitCode !== 0)
        Logger.w("WallpaperPicker", "Wallpaper helper exited with", exitCode);
      if (again) {
        again = false;
        root.refresh();
      }
    }
  }

  Process {
    id: applyProcess
    property string target: ""
    stderr: StdioCollector {
      id: applyErrors
    }
    onExited: exitCode => {
      if (exitCode !== 0) {
        Logger.w("WallpaperPicker", "Wallpaper command failed:", applyErrors.text);
        ToastService.showError(I18n.tr("wallpaper-picker.apply-failed"), applyErrors.text.trim() || Settings.data.wallpaperPicker.applyCommand);
        return;
      }
      root.applied(target);
      // Theming follows the daemon; ask it now instead of at the next poll
      WallpaperService.refresh();
    }
  }
}
