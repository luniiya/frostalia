.pragma library

// Style tokens and default appearance preferences are independent of colors.
// Add a complete entry here to offer another style in Settings.
var defaultStyle = "caelestia";
var definitions = {
  "caelestia": {
    "labelKey": "options.ui-style.caelestia",
    "views": {
      "controlCenter": "Modules/Panels/ControlCenter/CaelestiaControlCenter.qml",
      "mediaCard": "Modules/Cards/CaelestiaMediaCard.qml",
      "mediaPlayer": "Modules/Panels/Media/CaelestiaMediaPlayerContent.qml",
      "osd": "Modules/OSD/CaelestiaOsdContent.qml",
      "notificationContent": "Modules/Notification/CaelestiaNotificationContent.qml",
      "kdeConnectHome": "Modules/Panels/KdeConnect/CaelestiaKdeConnectHome.qml"
    },
    "tokens": {
      "controls": { "renderer": "caelestia" },
      "fontSizes": { "XXS": 8, "XS": 9, "S": 10, "M": 11, "L": 13, "XL": 16, "XXL": 18, "XXXL": 24 },
      "fontWeights": { "Regular": 400, "Medium": 500, "SemiBold": 600, "Bold": 700 },
      "fontFamily": "Rubik",
      "fixedFontFamily": "monospace",
      "radii": { "XXXS": 3, "XXS": 4, "XS": 8, "S": 12, "M": 16, "L": 20 },
      "inputRadii": { "XXXS": 3, "XXS": 4, "XS": 8, "S": 12, "M": 16, "L": 20 },
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
  },
  "material": {
    "labelKey": "options.ui-style.material",
    "views": {
      "controlCenter": "Modules/Panels/ControlCenter/MaterialControlCenter.qml",
      "mediaCard": "Modules/Cards/MaterialMediaCard.qml",
      "mediaPlayer": "Modules/Panels/Media/MaterialMediaPlayerContent.qml",
      "osd": "Modules/OSD/MaterialOsdContent.qml",
      "notificationContent": "Modules/Notification/MaterialNotificationContent.qml",
      "kdeConnectHome": "Modules/Panels/KdeConnect/MaterialKdeConnectHome.qml"
    },
    "settingsDefaults": { "ui": { "fontDefault": "Roboto", "boxBorderEnabled": false, "panelBackgroundOpacity": 1.0, "frostedGlass": true } },
    "tokens": {
      "controls": {
        "renderer": "material"
      },
      "fontSizes": {
        "XXS": 8,
        "XS": 9,
        "S": 10,
        "M": 11,
        "L": 14,
        "XL": 17,
        "XXL": 20,
        "XXXL": 26
      },
      "fontWeights": {
        "Regular": 400,
        "Medium": 500,
        "SemiBold": 500,
        "Bold": 700
      },
      "fontFamily": "Roboto",
      "fixedFontFamily": "monospace",
      "radii": {
        "XXXS": 4,
        "XXS": 8,
        "XS": 12,
        "S": 16,
        "M": 24,
        "L": 28
      },
      "inputRadii": {
        "XXXS": 4,
        "XXS": 8,
        "XS": 12,
        "S": 20,
        "M": 12,
        "L": 28
      },
      "borders": {
        "S": 1,
        "M": 2,
        "L": 3
      },
      "margins": {
        "XXXS": 1,
        "XXS": 2,
        "XS": 4,
        "S": 8,
        "M": 12,
        "L": 16,
        "XL": 24
      },
      "animations": {
        "Faster": 90,
        "Fast": 200,
        "Normal": 350,
        "Slow": 500,
        "Slowest": 800
      },
      "baseWidgetSize": 33,
      "sliderWidth": 200,
      "slider": {
        "heightRatio": 0.7,
        "trackRatio": 0.4,
        "cutoutRatio": 0.1,
        "trackOpacity": 1,
        "gradientDarkening": 1,
        "hitWidth": 40,
        "handleHeight": 44,
        "handleWidth": 4,
        "pressedHandleWidth": 2,
        "trackHeight": 16,
        "gap": 12
      },
      "toggle": {
        "sizeRatio": 0.8,
        "width": 52,
        "height": 32,
        "handleOff": 16,
        "handleOn": 24,
        "handlePressed": 28,
        "border": 2
      },
      "buttonGroup": {
        "gap": 2,
        "innerRadius": 8
      },
      "expandable": {
        "gap": 2,
        "outerRadius": 24,
        "innerRadius": 4
      },
      "field": {
        "radius": 12,
        "focusBorderWidth": 1
      },
      "weather": {
        "radius": 28,
        "tileRadius": 24,
        "cookieLobes": 9,
        "cookieDepth": 0.1
      },
      "menu": {
        "radius": 16,
        "padding": 8
      },
      "frostedGlass": {
        "panelOpacity": 0.85,
        "surfaceOpacity": 0.7
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

// Consumers treat tokens as read-only. Editable preferences live in each style’s TOML file.
function tokens(id) {
  return definitions[resolveId(id)].tokens;
}

// Include preset families in the picker even when they are application-loaded
// fonts, which fc-list does not enumerate.
function view(id, surface) {
  return definitions[resolveId(id)].views?.[surface] || "";
}

function fontFamilies() {
  return Object.keys(definitions).map(id => definitions[id].tokens?.fontFamily).filter((family, index, families) => family && families.indexOf(family) === index);
}

function fontFamily(id, configuredFamily, fixed, applicationFamily) {
  if (configuredFamily)
    return configuredFamily;
  const style = tokens(id);
  return (fixed ? style.fixedFontFamily : style.fontFamily) || applicationFamily;
}

function sliderGeometry(id, baseSize, heightRatio, scale) {
  const style = tokens(id);
  const slider = style.slider;
  if (style.controls.renderer === "material") {
    const ratio = baseSize / 33 * heightRatio / slider.heightRatio * scale;
    return {
      "knobDiameter": Math.round(slider.hitWidth * ratio),
      "handleHeight": Math.round(slider.handleHeight * ratio),
      "handleWidth": Math.max(1, slider.handleWidth * ratio),
      "pressedHandleWidth": Math.max(1, slider.pressedHandleWidth * ratio),
      "trackHeight": Math.max(1, Math.round(slider.trackHeight * ratio)),
      "cutoutExtra": 0,
      "gap": slider.gap * ratio
    };
  }
  const diameter = Math.round((baseSize * heightRatio * scale) / 2) * 2;
  return {
    "knobDiameter": diameter,
    "handleHeight": diameter,
    "handleWidth": diameter,
    "pressedHandleWidth": diameter,
    "gap": 0,
    "trackHeight": Math.round((diameter * slider.trackRatio * scale) / 2) * 2,
    "cutoutExtra": Math.round((baseSize * slider.cutoutRatio * scale) / 2) * 2
  };
}

// Keep track segments inside the control at endpoints and in narrow layouts.
// visualPosition already includes Qt's mirroring; mirrored selects the active side.
function splitSliderTrack(width, hitWidth, visualPosition, gap, mirrored) {
  const inset = Math.min(Math.max(0, width) / 2, hitWidth / 2);
  const end = Math.max(inset, width - inset);
  const center = inset + Math.max(0, Math.min(1, visualPosition)) * (end - inset);
  const leftWidth = Math.max(0, center - gap / 2 - inset);
  const rightX = Math.min(end, center + gap / 2);
  const rightWidth = Math.max(0, end - rightX);
  return {
    "activeX": mirrored ? rightX : inset,
    "activeWidth": mirrored ? rightWidth : leftWidth,
    "inactiveX": mirrored ? inset : rightX,
    "inactiveWidth": mirrored ? leftWidth : rightWidth,
    "start": inset,
    "end": end,
    "center": center
  };
}

// Material 3 connected button group: outer ends and the selected button are
// fully rounded, inner corners stay small.
function buttonGroupRadii(id, height, checked, isFirst, isLast) {
  const group = tokens(id).buttonGroup;
  if (!group)
    return null;
  const full = height / 2;
  const inner = Math.min(group.innerRadius, full);
  return { "left": checked || isFirst ? full : inner, "right": checked || isLast ? full : inner };
}

// Frosted glass: translucent panels and cards over the compositor blur.
// Null when the style has no glass look or it is turned off. `custom` holds the
// user's panelOpacity and surfaceOpacity; missing or invalid values use the style's.
function glass(id, enabled, custom) {
  const frosted = enabled ? tokens(id).frostedGlass : null;
  if (!frosted)
    return null;
  const pick = key => {
    const value = custom ? Number(custom[key]) : NaN;
    return isFinite(value) && custom[key] !== null && custom[key] !== "" ? Math.max(0, Math.min(1, value)) : frosted[key];
  };
  return { "panelOpacity": pick("panelOpacity"), "surfaceOpacity": pick("surfaceOpacity") };
}

// Panel background opacity before light-mode adaptation.
function panelOpacity(id, configured, glassEnabled, custom) {
  const frosted = glass(id, glassEnabled, custom);
  return frosted ? frosted.panelOpacity : configured;
}

// Filled fields keep their rounded shape on focus and use an outline for feedback.
function fieldShape(id, focused, cornerRadius) {
  const field = tokens(id).field;
  if (!field)
    return null;
  return {
    "radius": cornerRadius === undefined ? field.radius : cornerRadius,
    "borderWidth": focused ? field.focusBorderWidth : 0
  };
}

// Material 3 Expressive expandable card: the header stands alone when
// collapsed and joins the content as one connected card when expanded.
function expandableShape(id, expanded) {
  const shape = tokens(id).expandable;
  if (!shape)
    return null;
  return {
    "gap": shape.gap,
    "headerTop": shape.outerRadius,
    "headerBottom": expanded ? shape.innerRadius : shape.outerRadius,
    "contentTop": shape.innerRadius,
    "contentBottom": shape.outerRadius
  };
}

function toggleGeometry(id, baseSize, checked, pressed) {
  const style = tokens(id);
  const toggle = style.toggle;
  if (style.controls.renderer === "material") {
    const scale = baseSize / 26;
    const width = toggle.width * scale;
    const height = toggle.height * scale;
    const handle = (pressed ? toggle.handlePressed : checked ? toggle.handleOn : toggle.handleOff) * scale;
    const inset = (height - handle) / 2;
    return { "width": width, "height": height, "handle": handle, "x": checked ? width - handle - inset : inset };
  }
  const width = Math.round(baseSize * toggle.widthRatio) * 2;
  const handle = Math.round(baseSize * toggle.handleRatio) * 2;
  return { "width": width, "height": Math.round(baseSize * toggle.heightRatio) * 2, "handle": handle,
    "x": checked ? width - handle - toggle.handleInset : toggle.handleInset };
}
