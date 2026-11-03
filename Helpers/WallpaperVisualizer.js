.pragma library

// Wallpaper visualizer: audio waves along the screen edges, drawn over the wallpaper
// and, when the wallpaper has a clear subject, under a cut-out of that subject.
// Kept free of QML dependencies so it can be unit tested (see Tests/tst_wallpapervisualizer.qml).

var edgeChoices = ["all", "topBottom", "leftRight", "top", "bottom", "left", "right"];
var heightRange = [0.05, 0.5];
var opacityRange = [0.1, 1];
// Look of the waves, passed to the shader as is
var whitenessRange = [0, 1];
var rimRange = [0, 1];
var backWaveRange = [0, 1];
var softnessRange = [0.02, 0.3];

// Which edges carry a wave, as shader flags [top, bottom, left, right]
function edgeFlags(edges) {
  switch (edges) {
  case "top":
    return [1, 0, 0, 0];
  case "bottom":
    return [0, 1, 0, 0];
  case "left":
    return [0, 0, 1, 0];
  case "right":
    return [0, 0, 0, 1];
  case "topBottom":
    return [1, 1, 0, 0];
  case "leftRight":
    return [0, 0, 1, 1];
  default:
    return [1, 1, 1, 1];
  }
}

function clamp(value, range, fallback) {
  var number = Number(value);
  if (!isFinite(number))
    return fallback;
  return Math.max(range[0], Math.min(range[1], number));
}

// Animated wallpapers move under a still cut-out, so they never get one
function isAnimated(path) {
  return /\.gif$/i.test(String(path || ""));
}

// Last JSON line printed by wallpaper-cutout.py, or null when there is none
function parseResult(output) {
  var lines = String(output || "").trim().split("\n");
  for (var i = lines.length - 1; i >= 0; i--) {
    try {
      var parsed = JSON.parse(lines[i]);
      if (parsed && typeof parsed.source === "string")
        return parsed;
    } catch (e) {}
  }
  return null;
}

// Cut-out image to draw over the waves for this wallpaper, or ""
function cutoutFor(results, wallpaper) {
  if (!wallpaper || !results)
    return "";
  var result = results[wallpaper];
  if (!result || result.source !== wallpaper || !result.separable || !result.image)
    return "";
  return result.image;
}

// Whether a wallpaper still needs a cut-out run
function needsCutout(results, wallpaper) {
  return !!wallpaper && !isAnimated(wallpaper) && !(results && results[wallpaper]);
}

// Next wallpaper to cut out: the newest request that is still missing, or ""
function nextRequest(queue, results) {
  for (var i = queue.length - 1; i >= 0; i--) {
    if (needsCutout(results, queue[i]))
      return queue[i];
  }
  return "";
}

// The waves show while any audio plays; they give way to eco mode
function wavesActive(enabled, idle, ecoMode) {
  return !!enabled && !idle && !ecoMode;
}

// Edges after `edges` in edgeChoices, wrapping around (the Edit Desktop tile cycles them)
function nextEdges(edges) {
  var index = edgeChoices.indexOf(edges);
  return edgeChoices[(index + 1) % edgeChoices.length];
}

// What the depth effect does with this wallpaper: "off", "animated", "pending", "found" or "none"
function depthStatus(results, wallpaper, depth) {
  if (!depth)
    return "off";
  if (isAnimated(wallpaper))
    return "animated";
  var result = results ? results[wallpaper] : null;
  if (!result)
    return "pending";
  return cutoutFor(results, wallpaper) ? "found" : "none";
}

// Translation keys for the Edit Desktop effect tiles
var edgeLabelKeys = {
  "all": "panels.audio.wallpaper-visualizer-edges-all",
  "topBottom": "panels.audio.wallpaper-visualizer-edges-top-bottom",
  "leftRight": "panels.audio.wallpaper-visualizer-edges-left-right",
  "top": "panels.audio.wallpaper-visualizer-edges-top",
  "bottom": "panels.audio.wallpaper-visualizer-edges-bottom",
  "left": "panels.audio.wallpaper-visualizer-edges-left",
  "right": "panels.audio.wallpaper-visualizer-edges-right"
};
var depthLabelKeys = {
  "off": "panels.desktop-widgets.effect-off",
  "animated": "panels.desktop-widgets.effect-depth-animated",
  "pending": "panels.desktop-widgets.effect-depth-pending",
  "found": "panels.desktop-widgets.effect-depth-found",
  "none": "panels.desktop-widgets.effect-depth-none"
};

function edgeLabelKey(edges) {
  return edgeLabelKeys[edges] || edgeLabelKeys["all"];
}

function depthLabelKey(status) {
  return depthLabelKeys[status] || depthLabelKeys["off"];
}

// Shader uniforms for the look settings, clamped; out of range or missing values fall back to the defaults
function look(prefs) {
  prefs = prefs || {};
  return {
    "whiteness": clamp(prefs.whiteness, whitenessRange, 0.65),
    "rim": clamp(prefs.rim, rimRange, 0.85),
    "backWave": clamp(prefs.backWave, backWaveRange, 0.35),
    "softness": clamp(prefs.softness, softnessRange, 0.08)
  };
}

// A made-up spectrum for the Edit Desktop preview, `t` seconds in: a few slow beats
// sweeping the bands, louder in the lows like music, every value within 0..1
function demoSpectrum(count, t) {
  var values = [];
  var beat = Math.pow(0.5 + 0.5 * Math.sin(t * 2 * Math.PI * 1.8), 3);
  for (var i = 0; i < count; i++) {
    var band = count > 1 ? i / (count - 1) : 0;
    var lows = (1 - band) * (0.35 + 0.5 * beat);
    var sweep = 0.3 * (0.5 + 0.5 * Math.sin(band * 9 - t * 3.1));
    var shimmer = 0.15 * (0.5 + 0.5 * Math.sin(band * 23 + t * 5.3));
    values.push(Math.max(0, Math.min(1, lows + sweep * (0.4 + 0.6 * band) + shimmer * band)));
  }
  return values;
}

// The effect the Edit Desktop card previews: the hovered tile's, or the waves while their settings are open; "" for none
function previewEffect(hovered, settingsOpen) {
  if (hovered)
    return hovered;
  return settingsOpen ? "waves" : "";
}

// Hint shown on the card for a previewed effect
var hintKeys = {
  "waves": "panels.desktop-widgets.effect-hint-waves",
  "depth": "panels.desktop-widgets.effect-hint-depth",
  "edges": "panels.desktop-widgets.effect-hint-edges"
};

function hintKey(effect) {
  return hintKeys[effect] || "";
}

// The spectrum runs around the screen's border as one loop, in `lobes` mirrored copies
// (lows in the middle of each, highs where two meet). An odd count never lines up with
// the four edges, so the corners don't always get the quiet highs; edges meeting at a
// corner sit at the same point of the loop, so their waves meet at the same height.
var lobes = 3;

// Bands the waves are drawn from: the spectrum averaged down to this many, so each
// bump of a wave is wide and rolling instead of one narrow spike per band
var waveBands = 12;

// `values` averaged into `count` equal groups (fewer values come back as they are)
function bins(values, count) {
  var n = values ? values.length : 0;
  if (n <= count)
    return values ? Array.prototype.slice.call(values) : [];
  var out = [];
  for (var b = 0; b < count; b++) {
    var from = Math.floor(b * n / count);
    var to = Math.max(from + 1, Math.floor((b + 1) * n / count));
    var sum = 0;
    for (var i = from; i < to; i++) {
      var v = Number(values[i]);
      sum += isFinite(v) ? v : 0;
    }
    out.push(sum / (to - from));
  }
  return out;
}

// The frame: a wave floor all round the border, so quiet bands never leave gaps, that
// goes away with the music. Its height is `frameShare` of the tallest wave times the
// frame level from frameLevel()
var frameShare = 0.1;

// Frame level, 0..1, from the tallest band right now: 1 whenever any band reaches
// `knee` (most of any song), less only once the whole song gets very quiet. It follows a
// rise at once and a drop by half every `halfLife` seconds, so it doesn't flicker.
// `previous` is the last call's result; `dt` the seconds since it.
function frameLevel(values, previous, dt, knee, halfLife) {
  var tallest = 0;
  for (var i = 0; i < (values ? values.length : 0); i++) {
    var v = Number(values[i]);
    if (isFinite(v))
      tallest = Math.max(tallest, v);
  }
  var target = Math.max(0, Math.min(1, tallest / Math.max(knee || 0.3, 0.001)));
  var last = isFinite(previous) ? Math.max(0, Math.min(1, previous)) : 0;
  if (target >= last)
    return target;
  return Math.max(target, last * Math.pow(0.5, Math.max(0, dt) / Math.max(halfLife || 0.6, 0.001)));
}

// How far the spectrum has slid around the loop after `t` seconds, in turns: a slow,
// irregular back and forth (incommensurate sines, so it doesn't visibly repeat) that
// gives every part of the border its share of the lows over time
function drift(t) {
  return 0.18 * Math.sin(t * 0.043) + 0.11 * Math.sin(t * 0.071 + 1.3) + 0.07 * Math.sin(t * 0.113 + 2.1);
}
