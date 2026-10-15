.pragma library

// Current wallpaper per screen, read from the system wallpaper daemon (awww/swww or hyprpaper).
// Kept free of QML dependencies so it can be unit tested (see Tests/tst_systemwallpaper.qml).

// awww/swww `query`:   ": eDP-1: 2256x1504, scale: 1, currently displaying: image: /path/to/img.png"
//                      (older swww has no leading ": ")
// hyprpaper `listactive`: "eDP-1 = /path/to/img.png"
// Solid colors ("currently displaying: color: 000000") have no image and are skipped.
function parseQuery(output) {
  var result = {};
  var lines = String(output || "").split("\n");
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i].trim();
    var m = line.match(/^(?::\s*)?([^\s:]+):\s.*currently displaying:\s*image:\s*(.+)$/);
    if (!m)
      m = line.match(/^([^\s=]+)\s*=\s*(\/.+)$/);
    if (m)
      result[m[1]] = m[2].trim();
  }
  return result;
}

// Screens whose wallpaper differs between two parsed maps (added or changed, not removed)
function changedScreens(previous, current) {
  var changed = [];
  for (var screen in current) {
    if (!previous || previous[screen] !== current[screen])
      changed.push(screen);
  }
  return changed;
}

// Wallpaper for a screen, falling back to any screen's wallpaper (e.g. a screen the daemon
// doesn't report yet), or "" when the daemon reports nothing
function wallpaperFor(wallpapers, screenName) {
  if (!wallpapers)
    return "";
  if (screenName && wallpapers[screenName])
    return wallpapers[screenName];
  for (var screen in wallpapers)
    return wallpapers[screen];
  return "";
}
