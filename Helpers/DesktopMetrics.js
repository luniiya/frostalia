.pragma library

// Fixed sizes for desktop widgets. They do not follow the UI style or the UI scale, so a widget has the
// same footprint everywhere and a saved layout (positions and spacing) stays valid.
var fontSizes = {
  "XXS": 8,
  "XS": 9,
  "S": 10,
  "M": 11,
  "L": 13,
  "XL": 16,
  "XXL": 18,
  "XXXL": 24
};

var margins = {
  "XXXS": 1,
  "XXS": 2,
  "XS": 4,
  "S": 6,
  "M": 9,
  "L": 13,
  "XL": 18
};

// Footprint of the analog/binary clock (and the timer, which matches it) at a widget scale.
function clockFootprint(widgetScale) {
  var face = Math.round(Math.round(fontSizes.XXXL * 2.5 * widgetScale) * 1.9);
  var padding = Math.round(margins.XL * widgetScale);
  return Math.round(face + padding * 2);
}
