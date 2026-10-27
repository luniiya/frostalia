.pragma library

// Wallpaper visualizer: audio waves along the screen edges, drawn over the wallpaper
// and, when the wallpaper has a clear subject, under a cut-out of that subject.
// Kept free of QML dependencies so it can be unit tested (see Tests/tst_wallpapervisualizer.qml).

var edgeChoices = ["all", "topBottom", "bottom"];
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
  case "bottom":
    return [0, 1, 0, 0];
  case "topBottom":
    return [1, 1, 0, 0];
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
  "bottom": "panels.audio.wallpaper-visualizer-edges-bottom"
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

// Per-band auto-gain, so every part of an edge moves: highs carry far less energy than
// lows and would barely stir next to them. Each band is divided by its own recent peak,
// which decays by half every `halfLife` seconds; `floor` keeps silence and noise from
// being blown up, so no sound still means no waves. `peaks` is the previous call's
// result (or []); `dt` the seconds since it. Returns { values, peaks }.
function equalize(values, peaks, dt, halfLife, floor) {
  var decay = Math.pow(0.5, Math.max(0, dt) / Math.max(halfLife || 2, 0.001));
  var minPeak = floor === undefined ? 0.08 : floor;
  var out = [];
  var next = [];
  for (var i = 0; i < values.length; i++) {
    var v = Number(values[i]);
    v = isFinite(v) ? Math.max(0, Math.min(1, v)) : 0;
    var previous = peaks && isFinite(peaks[i]) ? peaks[i] : 0;
    var peak = Math.max(v, previous * decay, minPeak);
    next.push(peak);
    out.push(Math.min(1, v / peak));
  }
  return {
    "values": out,
    "peaks": next
  };
}
