.pragma library

// Style tokens are independent of colors and saved user preferences.
// Add a complete entry here to offer another style in Settings.
var defaultStyle = "caelestia";
var definitions = {
  "caelestia": {
    "labelKey": "options.ui-style.caelestia",
    "tokens": {
      "fontSizes": { "XXS": 8, "XS": 9, "S": 10, "M": 11, "L": 13, "XL": 16, "XXL": 18, "XXXL": 24 },
      "fontWeights": { "Regular": 400, "Medium": 500, "SemiBold": 600, "Bold": 700 },
      "fontFamily": "",
      "fixedFontFamily": "monospace",
      "radii": { "XXXS": 3, "XXS": 4, "XS": 8, "S": 12, "M": 16, "L": 20 },
      "inputRadii": { "XXXS": 3, "XXS": 4, "XS": 8, "S": 12, "M": 16, "L": 20 },
      "screenRadius": 20,
      "borders": { "S": 1, "M": 2, "L": 3 },
      "margins": { "XXXS": 1, "XXS": 2, "XS": 4, "S": 6, "M": 9, "L": 13, "XL": 18 },
      "animations": { "Faster": 75, "Fast": 150, "Normal": 300, "Slow": 450, "Slowest": 750 },
      "baseWidgetSize": 33,
      "sliderWidth": 200,
      "slider": {
        "heightRatio": 0.7,
        "trackRatio": 0.4,
        "cutoutRatio": 0.1,
        "trackOpacity": 0.5,
        "gradientDarkening": 1.2
      },
      "toggle": {
        "sizeRatio": 0.8,
        "widthRatio": 0.85,
        "heightRatio": 0.5,
        "handleRatio": 0.4,
        "handleInset": 3
      }
    }
  }
};

function resolveId(id) {
  return Object.prototype.hasOwnProperty.call(definitions, id) ? id : defaultStyle;
}

function choices() {
  return Object.keys(definitions).map(id => ({ "key": id, "labelKey": definitions[id].labelKey }));
}

// Consumers treat tokens as read-only; changing a style never writes its values
// into settings, so personal font and rounding adjustments survive switching.
function tokens(id) {
  return definitions[resolveId(id)].tokens;
}

function fontFamily(id, configuredFamily, fixed, applicationFamily) {
  if (configuredFamily)
    return configuredFamily;
  const style = tokens(id);
  return (fixed ? style.fixedFontFamily : style.fontFamily) || applicationFamily;
}

function sliderGeometry(id, baseSize, heightRatio, scale) {
  const slider = tokens(id).slider;
  const diameter = Math.round((baseSize * heightRatio * scale) / 2) * 2;
  return {
    "knobDiameter": diameter,
    "trackHeight": Math.round((diameter * slider.trackRatio * scale) / 2) * 2,
    "cutoutExtra": Math.round((baseSize * slider.cutoutRatio * scale) / 2) * 2
  };
}
