.pragma library

// Container outline appearance (NBox and other boxes using Style.boxBorderColor).
// Kept free of QML dependencies so it can be unit tested (see Tests/tst_outlinestyle.qml).
// Colors are plain { r, g, b, a } objects with channels in [0, 1].

var minWidth = 1;
var maxWidth = 6;

function clamp(v, lo, hi) {
  return Math.min(hi, Math.max(lo, v));
}

// Outline width in pixels for a width setting and the UI scale; never thinner than 1px
function borderWidth(setting, uiScale) {
  var w = clamp(Math.round(Number(setting) || minWidth), minWidth, maxWidth);
  return Math.max(1, Math.round(w * (uiScale > 0 ? uiScale : 1)));
}

// Brightness in [-100, 100]: positive mixes toward white, negative toward black, 0 keeps the color
function adjustBrightness(color, brightness) {
  var b = clamp(Number(brightness) || 0, -100, 100) / 100;
  var target = b > 0 ? 1 : 0;
  var t = Math.abs(b);
  return {
    "r": color.r + (target - color.r) * t,
    "g": color.g + (target - color.g) * t,
    "b": color.b + (target - color.b) * t,
    "a": color.a
  };
}

// Final outline color: brightness, then opacity in percent of the color's own alpha
function outlineColor(color, brightness, opacityPercent) {
  var c = adjustBrightness(color, brightness);
  var opacity = opacityPercent === undefined ? 100 : clamp(Number(opacityPercent), 0, 100);
  c.a = color.a * opacity / 100;
  return c;
}
