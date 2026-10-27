.pragma library

// Wallpaper visualizer: audio waves along the screen edges, drawn over the wallpaper
// and, when the wallpaper has a clear subject, under a cut-out of that subject.
// Kept free of QML dependencies so it can be unit tested (see Tests/tst_wallpapervisualizer.qml).

var edgeChoices = ["all", "topBottom", "bottom"];
var heightRange = [0.05, 0.5];
var opacityRange = [0.1, 1];

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
