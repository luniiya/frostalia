pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../../Helpers/WallpaperVisualizer.js" as WallpaperVisualizer
import qs.Commons

// Cuts the subject out of each wallpaper shown, for the wallpaper visualizer's depth
// effect. The work happens in Scripts/python/src/wallpaper/wallpaper-cutout.py, which
// runs rembg through uv (the first run downloads the models) and caches its result,
// so only a wallpaper's first appearance takes time.
Singleton {
  id: root

  // { wallpaperPath: result } as printed by the script
  property var results: ({})
  // Wallpapers asked for, newest last
  property var queue: []
  property bool unavailable: false

  readonly property string script: Quickshell.shellDir + "/Scripts/python/src/wallpaper/wallpaper-cutout.py"
  readonly property string cacheDir: Settings.cacheDir + "cutouts"

  function cutoutFor(wallpaper) {
    return WallpaperVisualizer.cutoutFor(results, wallpaper);
  }

  function request(wallpaper) {
    if (unavailable || !WallpaperVisualizer.needsCutout(results, wallpaper))
      return;
    queue = queue.filter(path => path !== wallpaper).concat([wallpaper]);
    runNext();
  }

  function runNext() {
    if (cutProcess.running)
      return;
    const next = WallpaperVisualizer.nextRequest(queue, results);
    queue = [];
    if (!next)
      return;
    Logger.d("WallpaperCutout", "Cutting out", next);
    cutProcess.wallpaper = next;
    // Through sh so a missing uv shows up as exit code 127
    cutProcess.command = ["sh", "-c", "command -v uv >/dev/null || exit 127; exec uv run -q --python 3.12 --with \"rembg[cpu]\" python \"$@\"", "sh", script, next, cacheDir];
    cutProcess.running = true;
  }

  Process {
    id: cutProcess
    property string wallpaper: ""
    stdout: StdioCollector {
      id: cutOutput
    }
    stderr: StdioCollector {
      id: cutErrors
    }
    onExited: exitCode => {
      const result = WallpaperVisualizer.parseResult(cutOutput.text);
      if (exitCode === 127) {
        root.unavailable = true;
        Logger.w("WallpaperCutout", "uv is not installed; the wallpaper visualizer has no depth effect");
      } else if (!result) {
        Logger.w("WallpaperCutout", "No cut-out for", wallpaper, cutErrors.text.trim().split("\n").slice(-1)[0] || ("exit " + exitCode));
      }
      const next = Object.assign({}, root.results);
      // A failed run counts as "no subject", so it is not retried in a loop
      next[wallpaper] = result || {
        "source": wallpaper,
        "separable": false,
        "image": ""
      };
      root.results = next;
      Logger.d("WallpaperCutout", wallpaper, next[wallpaper].separable ? "has a subject" : "has no separable subject");
      root.runNext();
    }
  }
}
