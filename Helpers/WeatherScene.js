.pragma library

// Scene selection and sky palettes for the animated weather backdrop.
// Adapted from Clavis Shell (GPL-3.0), itself a recreation of Steve Gardner's
// Animated Weather Cards (MIT, see licenses/AnimatedWeatherCards-MIT.txt).

// "clear", "partly", "overcast", "rain", "snow" or "storm" for a WMO code.
function type(code) {
  if (code >= 95)
    return "storm";
  if ((code >= 71 && code <= 77) || code === 85 || code === 86)
    return "snow";
  if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82))
    return "rain";
  if (code === 0)
    return "clear";
  if (code === 1 || code === 2)
    return "partly";
  return "overcast";
}

// Strong wind (m/s) on dry weather blows leaves and faster clouds.
function windy(sceneType, windSpeedMs, windGustsMs) {
  var strength = Math.max(isFinite(windSpeedMs) ? windSpeedMs : 0, isFinite(windGustsMs) ? windGustsMs : 0);
  return strength >= 8 && (sceneType === "clear" || sceneType === "partly" || sceneType === "overcast");
}

// Windy dry weather is drawn with full cloud cover.
function visualType(sceneType, isWindy) {
  return isWindy ? "overcast" : sceneType;
}

function cloudBandCount(visual) {
  if (visual === "clear")
    return 0;
  return visual === "partly" ? 2 : 3;
}

var _palettes = {
  "clear_day": ["#7fc5e5", "#dde7ec", "#f7fbfd", "#fff6cd", "#f0efed", "#e0dfdd", "#cecdcb", "#fff2c0"],
  "clear_night": ["#45578f", "#8ca0d8", "#c0cbef", "#e8edff", "#eef2fb", "#d7dce8", "#c4cad8", "#eef2ff"],
  "overcast_day": ["#9aadb9", "#c8d2d8", "#eef3f5", "#f7fafb", "#ecebea", "#dddcd9", "#cbc9c6", "#eaf0f5"],
  "overcast_night": ["#53657a", "#8a9bad", "#c1ccd4", "#e7edf1", "#dde2eb", "#c3c8d2", "#aeb4c0", "#dae6f4"],
  "rain_day": ["#a5b7d2", "#ced8e4", "#edf2f7", "#f6f9fd", "#ecebea", "#dddcd9", "#cbc9c6", "#d8ecff"],
  "rain_night": ["#4a617d", "#879cb7", "#bcc9d9", "#e3ebf4", "#dde2eb", "#c3c8d2", "#aeb4c0", "#cee5ff"],
  "snow_day": ["#a5bdd5", "#d1dfe9", "#f7fbfd", "#ffffff", "#f2f2f1", "#e4e3e1", "#d3d2d0", "#ffffff"],
  "snow_night": ["#566d91", "#9ab0cb", "#d1dce8", "#f0f5fa", "#edf1f8", "#d5dae4", "#c4ccd8", "#ffffff"],
  "storm_day": ["#78879a", "#adb8c9", "#dbe1ea", "#f5f7fc", "#9fa4ad", "#8b8e98", "#7b7988", "#d7e8ff"],
  "storm_night": ["#49516f", "#8790b0", "#c0c6da", "#e9ecf8", "#8f949d", "#7d8089", "#6d6c79", "#d3dfff"]
};

function palette(visual, night) {
  var base = visual === "partly" ? "clear" : visual;
  var colors = _palettes[base + (night ? "_night" : "_day")] || ["#86a0b5", "#bccad5", "#e4ebf1", "#f6f9fb", "#f0efed", "#e0dfdd", "#cecdcb", "#eef3f8"];
  return {
    "top": colors[0],
    "mid": colors[1],
    "bottom": colors[2],
    "glow": colors[3],
    "cloud1": colors[4],
    "cloud2": colors[5],
    "cloud3": colors[6],
    "particle": colors[7]
  };
}

function _luminance(hex) {
  var value = hex.replace("#", "");
  var channels = [0, 2, 4].map(function (offset) {
    var c = parseInt(value.slice(offset, offset + 2), 16) / 255;
    return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
  });
  return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2];
}

// Readable text over the upper half of the sky, where the hero text sits.
function onSkyColor(colors) {
  var luminance = (_luminance(colors.top) + _luminance(colors.mid)) / 2;
  return luminance > 0.3 ? "#1b2430" : "#f4f6fb";
}
