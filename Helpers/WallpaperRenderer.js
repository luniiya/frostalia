.pragma library

// The shell's own wallpaper renderer (Settings > Wallpaper, off by default): which folder
// and picture to show, which transition plays and how it is timed. The window is
// Modules/Background/WallpaperLayer.qml and the state lives in Services/UI/WallpaperService.qml;
// this file has no QML dependencies so it can be unit tested (Tests/tst_wallpaperrenderer.qml).
//
// The transition styles and their timing follow SekaiPop's wallpaper manager
// (github.com/Blapples/SekaiPop, GPL-3.0); the classic ones are Noctalia's.

// Formats shown from a folder. Qt decodes jpg/png/bmp/gif itself; the rest go through
// ImageMagick when the cache pre-scales them (ImageCacheService.getLarge).
var imageExtensions = ["jpg", "jpeg", "png", "webp", "bmp", "gif", "avif", "jxl", "tif", "tiff", "heic", "heif"];

// Styles a transition setting can name. "sekai" ones are SekaiPop's shaders, "classic" ones
// Noctalia's (Shaders/frag/wp_*.frag); each family has its own ShaderEffect in WallpaperLayer.qml.
var styles = {
  "ring": {
    "shader": "wp_sekai_ring",
    "family": "sekai",
    "linear": true
  },
  "star": {
    "shader": "wp_sekai_star",
    "family": "sekai",
    "linear": true
  },
  "iris": {
    "shader": "wp_sekai_iris",
    "family": "sekai",
    "linear": true
  },
  "blocks": {
    "shader": "wp_sekai_blocks",
    "family": "sekai",
    "linear": true
  },
  "flash": {
    "shader": "wp_sekai_flash",
    "family": "sekai",
    "linear": false
  },
  "fade": {
    "shader": "wp_fade",
    "family": "classic",
    "linear": false
  },
  "wipe": {
    "shader": "wp_wipe",
    "family": "classic",
    "linear": false
  },
  "disc": {
    "shader": "wp_disc",
    "family": "classic",
    "linear": false
  },
  "stripes": {
    "shader": "wp_stripes",
    "family": "classic",
    "linear": false
  },
  "pixelate": {
    "shader": "wp_pixelate",
    "family": "classic",
    "linear": false
  },
  "honeycomb": {
    "shader": "wp_honeycomb",
    "family": "classic",
    "linear": false
  }
};

// What "random" picks from. Plain fade is left out, as in SekaiPop: it is the fallback,
// not a look of its own.
var randomPool = ["ring", "star", "iris", "blocks", "flash", "wipe", "disc", "stripes", "pixelate", "honeycomb"];

// The ring shader's variants (its `transitionStyle` uniform)
var ringVariants = ["ring", "petal", "echo", "swirl"];

// SekaiPop's iris runs 2 s next to the ring's 1.3 s; it keeps that ratio to the duration setting
var irisRatio = 2000 / 1300;

// SekaiPop's own band colours, for colors = "sekai"
var sekaiColors = {
  "white": "#ffffff",
  "pink": "#ff8fd6",
  "cyan": "#22e6d3",
  "green": "#00ffcb"
};

function expandHome(path, home) {
  var p = String(path || "").trim();
  if (p === "~")
    return home;
  if (p.indexOf("~/") === 0)
    return home + p.substring(1);
  return p;
}

// Folder path without a trailing slash ("/" stays "/")
function normalizeFolder(path, home) {
  var p = expandHome(path, home);
  while (p.length > 1 && p.charAt(p.length - 1) === "/")
    p = p.substring(0, p.length - 1);
  return p;
}

function isImage(name) {
  var n = String(name || "");
  var dot = n.lastIndexOf(".");
  if (dot <= 0 || n.charAt(dot - 1) === "/")
    return false;
  return imageExtensions.indexOf(n.substring(dot + 1).toLowerCase()) >= 0;
}

function baseName(path) {
  var p = String(path || "");
  return p.substring(p.lastIndexOf("/") + 1);
}

// Image paths only, sorted by file name the way a file manager would ("2" before "10")
function sortedImages(paths) {
  var list = [];
  for (var i = 0; i < (paths || []).length; i++) {
    if (isImage(paths[i]))
      list.push(String(paths[i]));
  }
  list.sort(function (a, b) {
    return naturalCompare(baseName(a), baseName(b)) || (a < b ? -1 : a > b ? 1 : 0);
  });
  return list;
}

// Case-insensitive, with runs of digits compared as numbers. (QML's localeCompare
// ignores the `numeric` option.)
function naturalCompare(a, b) {
  var x = String(a).toLowerCase().match(/\d+|\D+/g) || [];
  var y = String(b).toLowerCase().match(/\d+|\D+/g) || [];
  for (var i = 0; i < Math.min(x.length, y.length); i++) {
    if (x[i] === y[i])
      continue;
    var nx = /^\d/.test(x[i]), ny = /^\d/.test(y[i]);
    if (nx && ny && Number(x[i]) !== Number(y[i]))
      return Number(x[i]) - Number(y[i]);
    return x[i] < y[i] ? -1 : 1;
  }
  return x.length - y.length;
}

// "light" or "dark": the IPC override when one is set, else the shell's color mode
function modeFor(darkMode, override) {
  if (override === "light" || override === "dark")
    return override;
  return darkMode ? "dark" : "light";
}

// An IPC mode argument: "light", "dark", "auto" (follow the shell), or "" when unknown
function normalizeMode(arg) {
  var m = String(arg || "").trim().toLowerCase();
  if (m === "light" || m === "dark")
    return m;
  if (m === "auto" || m === "follow" || m === "system" || m === "shell")
    return "auto";
  return "";
}

function folderFor(mode, prefs, home) {
  if (!prefs)
    return "";
  return normalizeFolder(mode === "dark" ? prefs.darkFolder : prefs.lightFolder, home);
}

// Which mode's folder a picture is in ("" for neither), so a picture set over IPC is
// remembered for the mode it belongs to
function modeOfPath(path, prefs, home) {
  var p = String(path || "");
  var dark = folderFor("dark", prefs, home);
  var light = folderFor("light", prefs, home);
  if (dark && p.indexOf(dark + "/") === 0)
    return "dark";
  if (light && p.indexOf(light + "/") === 0)
    return "light";
  return "";
}

// The mode a picture shown over IPC is remembered for: the one asked, else its folder's,
// else the current one
function modeForPicture(path, asked, prefs, home, current) {
  var m = normalizeMode(asked);
  if (m === "light" || m === "dark")
    return m;
  return modeOfPath(path, prefs, home) || current;
}

// A random entry that is not in `avoid` (falls back to anything but avoid[0]); "" if none
function pickRandom(list, avoid, rand) {
  var all = list || [];
  var skip = avoid || [];
  var pool = all.filter(function (p) {
    return skip.indexOf(p) < 0;
  });
  if (pool.length === 0)
    pool = all.filter(function (p) {
      return p !== skip[0];
    });
  if (pool.length === 0)
    return "";
  var r = typeof rand === "function" ? rand() : Math.random();
  return pool[Math.min(pool.length - 1, Math.floor(r * pool.length))];
}

// The entry `delta` steps from `current`, wrapping; from outside the list, the first (or last)
function step(list, current, delta) {
  if (!list || list.length === 0)
    return "";
  var i = list.indexOf(current);
  if (i < 0)
    return delta < 0 ? list[list.length - 1] : list[0];
  var n = list.length;
  return list[(((i + delta) % n) + n) % n];
}

// The picture a mode starts on: the one it showed last if it is still in the folder,
// else a random one
function startingPicture(list, remembered, rand) {
  if (remembered && (list || []).indexOf(remembered) >= 0)
    return remembered;
  return pickRandom(list, [], rand);
}

// The style one wallpaper change plays. `setting` is a style name, "random" or "none";
// "random" never plays the same style twice in a row.
function styleForSwitch(setting, last, rand) {
  if (setting === "none")
    return "none";
  if (setting === "random")
    return pickRandom(randomPool, [last], rand);
  return styles[setting] ? setting : "ring";
}

function shaderFor(style) {
  return styles[style] ? styles[style].shader : "";
}

function familyFor(style) {
  return styles[style] ? styles[style].family : "";
}

// Milliseconds a style runs for, from the duration setting
function durationFor(style, base) {
  var ms = Math.max(0, Math.round(Number(base) || 0));
  if (style === "none")
    return 0;
  if (style === "iris")
    return Math.round(ms * irisRatio);
  return ms;
}

// SekaiPop's ring, star, iris and blocks ease inside the shader and want linear progress
function linearFor(style) {
  return !!(styles[style] && styles[style].linear);
}

function ringVariantIndex(name) {
  var i = ringVariants.indexOf(name);
  return i < 0 ? 0 : i;
}

// Per-change look for the classic styles, rolled like Noctalia did: a wipe direction
// (0 left, 1 right, 2 up, 3 down), a disc or honeycomb origin and a stripe angle
function classicParams(rand) {
  var r = typeof rand === "function" ? rand : Math.random;
  return {
    "direction": Math.min(3, Math.floor(r() * 4)),
    "centerX": r(),
    "centerY": r(),
    "angle": Math.round(r() * 360)
  };
}

// Size in device pixels that a screen's wallpaper is pre-scaled to
function cacheSize(width, height, scale, zoom) {
  var s = (Number(scale) > 0 ? Number(scale) : 1) * (Number(zoom) >= 1 ? Number(zoom) : 1);
  return {
    "width": Math.max(1, Math.round((Number(width) || 0) * s)),
    "height": Math.max(1, Math.round((Number(height) || 0) * s))
  };
}

// Parallax: the picture is zoomed in by `amount` percent and slides across the screen as
// the workspace changes, from the left edge on the first workspace to the right edge on
// the last. The zoom is also the cache's, so the slid picture stays sharp.
function parallaxZoom(enabled, amount) {
  if (!enabled)
    return 1;
  var a = Math.min(50, Math.max(0, Number(amount) || 0));
  return 1 + a / 100;
}

// The workspace shown on `output`, from CompositorService.workspaces entries; 0 when none
function activeWorkspace(workspaces, output) {
  var fallback = 0;
  for (var i = 0; i < (workspaces || []).length; i++) {
    var ws = workspaces[i];
    if (!ws || !ws.isActive)
      continue;
    if (ws.output === output)
      return Number(ws.idx) || 0;
    // Compositors without per-output workspaces leave output empty
    if (!ws.output && ws.isFocused)
      fallback = Number(ws.idx) || 0;
  }
  return fallback;
}

// 0 (left) to 1 (right) for workspace `idx` of `count`; the middle when there's nothing to slide
function parallaxFraction(idx, count) {
  var n = Math.floor(Number(count) || 0);
  var i = Number(idx) || 0;
  if (n < 2 || i < 1)
    return 0.5;
  return Math.min(1, Math.max(0, (i - 1) / (n - 1)));
}

// Where the zoomed picture sits: its offset from the screen's origin along one axis
function parallaxShift(fraction, size, zoom) {
  var spare = (Number(size) || 0) * ((Number(zoom) || 1) - 1);
  return -Math.max(0, spare) * Math.min(1, Math.max(0, Number(fraction) || 0));
}

// Pictures to pre-scale: the next ones first (so "next" and the upcoming random are
// instant), then the rest of the folder in order, nothing twice, the current one skipped
function precacheOrder(list, current, upcoming) {
  var order = [];
  var add = function (p) {
    if (p && p !== current && order.indexOf(p) < 0 && (list || []).indexOf(p) >= 0)
      order.push(p);
  };
  for (var i = 0; i < (upcoming || []).length; i++)
    add(upcoming[i]);
  var start = Math.max(0, (list || []).indexOf(current));
  for (var j = 0; j < (list || []).length; j++)
    add(list[(start + j) % list.length]);
  return order;
}

function parseHex(hex) {
  var h = String(hex || "").replace("#", "");
  if (h.length === 8)
    h = h.substring(2); // #AARRGGBB
  if (h.length === 3)
    h = h.charAt(0) + h.charAt(0) + h.charAt(1) + h.charAt(1) + h.charAt(2) + h.charAt(2);
  if (!/^[0-9a-fA-F]{6}$/.test(h))
    return null;
  return [parseInt(h.substring(0, 2), 16), parseInt(h.substring(2, 4), 16), parseInt(h.substring(4, 6), 16)];
}

function toHex(rgb) {
  return "#" + rgb.map(function (c) {
    var v = Math.max(0, Math.min(255, Math.round(c))).toString(16);
    return v.length < 2 ? "0" + v : v;
  }).join("");
}

// `a` moved `t` of the way to `b` (both "#rrggbb")
function mixHex(a, b, t) {
  var x = parseHex(a), y = parseHex(b);
  if (!x || !y)
    return a;
  return toHex([x[0] + (y[0] - x[0]) * t, x[1] + (y[1] - x[1]) * t, x[2] + (y[2] - x[2]) * t]);
}

// Largest channel difference, 0..1
function colorDistance(a, b) {
  var x = parseHex(a), y = parseHex(b);
  if (!x || !y)
    return 1;
  return Math.max(Math.abs(x[0] - y[0]), Math.abs(x[1] - y[1]), Math.abs(x[2] - y[2])) / 255;
}

// The band colours (white, pink, cyan, green) of the sekai transitions. "theme" takes them
// from the color scheme like SekaiPop's themed transitions: white tinted with the primary,
// cyan the primary, pink the secondary, green the tertiary. A scheme whose primary and
// secondary are nearly the same (monochrome ones) gets a lighter pink so the bands still read.
function transitionColors(mode, primary, secondary, tertiary) {
  if (mode !== "theme" || !parseHex(primary) || !parseHex(secondary))
    return sekaiColors;
  var pink = toHex(parseHex(secondary));
  if (colorDistance(primary, secondary) < 0.12)
    pink = mixHex(pink, "#ffffff", 0.45);
  return {
    "white": mixHex("#ffffff", primary, 0.1),
    "pink": pink,
    "cyan": toHex(parseHex(primary)),
    "green": parseHex(tertiary) ? toHex(parseHex(tertiary)) : toHex(parseHex(primary))
  };
}

// Random-change interval in milliseconds, 0 when off
function intervalMs(minutes) {
  var m = Number(minutes);
  return isFinite(m) && m > 0 ? Math.round(m * 60000) : 0;
}
