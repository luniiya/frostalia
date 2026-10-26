.pragma library

// Style tokens and default appearance preferences are independent of colors.
// Add a complete entry here to offer another style in Settings.
var defaultStyle = "material";
var definitions = {
  "caelestia": {
    "labelKey": "options.ui-style.caelestia",
    "settingsDefaults": { "ui": { "fontDefault": "Rubik", "boxBorderEnabled": true, "panelBackgroundOpacity": 0.93, "frostedGlass": false } },
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
      },
      // Desktop radial menu look; the shape preset fills the rest (Helpers/RadialMenu.js)
      "radialMenu": { "shape": "orbit" }
    }
  },
  // Keycap: bold sticker and keycap look. Every surface is an ink outline,
  // a thin cream ring, a fill and a hard shadow straight down; things pop in
  // with an overshoot. Panels reuse the Caelestia surface views, drawn with
  // keycap controls; bar widgets get their own faces from `barViews`.
  "keycap": {
    "labelKey": "options.ui-style.keycap",
    "settingsDefaults": { "ui": { "fontDefault": "Google Sans Flex", "boxBorderEnabled": true, "boxBorderWidth": 2, "panelBackgroundOpacity": 1.0, "frostedGlass": false } },
    "views": {
      "controlCenter": "Modules/Panels/ControlCenter/CaelestiaControlCenter.qml",
      "mediaCard": "Modules/Cards/CaelestiaMediaCard.qml",
      "mediaPlayer": "Modules/Panels/Media/CaelestiaMediaPlayerContent.qml",
      "osd": "Modules/OSD/CaelestiaOsdContent.qml",
      "notificationContent": "Modules/Notification/CaelestiaNotificationContent.qml",
      "kdeConnectHome": "Modules/Panels/KdeConnect/CaelestiaKdeConnectHome.qml"
    },
    // Bar widget faces, keyed by the name a bar widget passes as `faceView`.
    // "Plate" is the plain keycap used by widgets without a face of their own.
    "barViews": {
      "Plate": "Modules/Bar/Widgets/Keycap/PlateFace.qml",
      "ActiveWindow": "Modules/Bar/Widgets/Keycap/ActiveWindowFace.qml",
      "AudioVisualizer": "Modules/Bar/Widgets/Keycap/AudioVisualizerFace.qml",
      "Battery": "Modules/Bar/Widgets/Keycap/BatteryFace.qml",
      "Bluetooth": "Modules/Bar/Widgets/Keycap/BluetoothFace.qml",
      "Brightness": "Modules/Bar/Widgets/Keycap/BrightnessFace.qml",
      "Clock": "Modules/Bar/Widgets/Keycap/ClockFace.qml",
      "ControlCenter": "Modules/Bar/Widgets/Keycap/ControlCenterFace.qml",
      "DarkMode": "Modules/Bar/Widgets/Keycap/DarkModeFace.qml",
      "KdeConnect": "Modules/Bar/Widgets/Keycap/KdeConnectFace.qml",
      "KeepAwake": "Modules/Bar/Widgets/Keycap/KeepAwakeFace.qml",
      "KeyboardLayout": "Modules/Bar/Widgets/Keycap/KeyboardLayoutFace.qml",
      "Launcher": "Modules/Bar/Widgets/Keycap/LauncherFace.qml",
      "LockKeys": "Modules/Bar/Widgets/Keycap/LockKeysFace.qml",
      "MediaMini": "Modules/Bar/Widgets/Keycap/MediaMiniFace.qml",
      "Microphone": "Modules/Bar/Widgets/Keycap/MicrophoneFace.qml",
      "ModelUsage": "Modules/Bar/Widgets/Keycap/ModelUsageFace.qml",
      "Network": "Modules/Bar/Widgets/Keycap/NetworkFace.qml",
      "NightLight": "Modules/Bar/Widgets/Keycap/NightLightFace.qml",
      "NotificationHistory": "Modules/Bar/Widgets/Keycap/NotificationHistoryFace.qml",
      "PowerProfile": "Modules/Bar/Widgets/Keycap/PowerProfileFace.qml",
      "SessionMenu": "Modules/Bar/Widgets/Keycap/SessionMenuFace.qml",
      "Settings": "Modules/Bar/Widgets/Keycap/SettingsFace.qml",
      "SystemMonitor": "Modules/Bar/Widgets/Keycap/SystemMonitorFace.qml",
      "Taskbar": "Modules/Bar/Widgets/Keycap/TaskbarFace.qml",
      "Volume": "Modules/Bar/Widgets/Keycap/VolumeFace.qml",
      "VPN": "Modules/Bar/Widgets/Keycap/VpnFace.qml",
      "Weather": "Modules/Bar/Widgets/Keycap/WeatherFace.qml",
      "Workspace": "Modules/Bar/Widgets/Keycap/WorkspaceFace.qml",
      "WorkspaceKey": "Modules/Bar/Widgets/Keycap/WorkspaceKeyFace.qml"
    },
    "tokens": {
      "controls": { "renderer": "keycap" },
      "fontSizes": { "XXS": 8, "XS": 9, "S": 10, "M": 11, "L": 14, "XL": 17, "XXL": 20, "XXXL": 26 },
      "fontWeights": { "Regular": 500, "Medium": 600, "SemiBold": 700, "Bold": 800 },
      "fontFamily": "Google Sans Flex",
      // Tried in order when the preset font is not installed; Rubik is bundled.
      "fontFallbacks": ["Google Sans Flex", "Google Sans", "Rubik"],
      "fixedFontFamily": "monospace",
      "radii": { "XXXS": 4, "XXS": 6, "XS": 10, "S": 14, "M": 18, "L": 22 },
      "inputRadii": { "XXXS": 4, "XXS": 6, "XS": 9, "S": 12, "M": 14, "L": 18 },
      "borders": { "S": 2, "M": 2, "L": 3 },
      "margins": { "XXXS": 1, "XXS": 2, "XS": 4, "S": 7, "M": 10, "L": 14, "XL": 20 },
      "animations": { "Faster": 80, "Fast": 160, "Normal": 280, "Slow": 420, "Slowest": 700 },
      "baseWidgetSize": 33,
      "sliderWidth": 200,
      "slider": {
        "heightRatio": 0.7,
        "trackRatio": 0.45,
        "cutoutRatio": 0,
        "trackOpacity": 1,
        "gradientDarkening": 1
      },
      "toggle": {
        "sizeRatio": 0.8,
        "widthRatio": 0.9,
        "heightRatio": 0.5,
        "handleRatio": 0.36,
        "handleInset": 4
      },
      "keycap": {
        // Hard shadow depth at rest and while pressed, and the hover lift (px at scale 1).
        "depth": 3,
        "pressedDepth": 1,
        "hoverLift": 1,
        // Depth of bar faces, limited by the slack around the capsule.
        "barDepth": 2,
        "outline": 2,
        "ring": 1,
        "cream": "#fff3dc",
        // Easing.OutBack overshoot for release and pop-in animations.
        "overshoot": 2.2,
        "popOvershoot": 1.6,
        // Maximum sticker tilt in degrees.
        "tilt": 4
      },
      "radialMenu": { "shape": "chunky", "borderWidth": 2, "shadowY": 3, "keylineWidth": 1, "hoverLift": 3, "pressDepth": 2, "tilt": 4, "colors": { "keyline": "#fff3dc" } }
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
      },
      // Desktop radial menu look; the shape preset fills the rest (Helpers/RadialMenu.js)
      "radialMenu": { "shape": "segment", "cornerRadius": 10, "fillOpacity": 0.96 }
    }
  }
};

function resolveId(id) {
  return Object.prototype.hasOwnProperty.call(definitions, id) ? id : defaultStyle;
}

function choices() {
  return Object.keys(definitions).sort((a, b) => a === defaultStyle ? -1 : b === defaultStyle ? 1 : 0).map(id => ({ "key": id, "labelKey": definitions[id].labelKey }));
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

// Style-specific face of a bar widget, or "" to keep the shared look.
function barView(id, name) {
  const views = definitions[resolveId(id)].barViews;
  return views && name && Object.prototype.hasOwnProperty.call(views, name) ? views[name] : "";
}

function fontFamilies() {
  return Object.keys(definitions).map(id => definitions[id].tokens?.fontFamily).filter((family, index, families) => family && families.indexOf(family) === index);
}

// `available` (optional) lists installed families. When the configured or
// preset family is the style's preferred font and it is missing, the style's
// `fontFallbacks` are tried in order; the last one is used regardless.
function fontFamily(id, configuredFamily, fixed, applicationFamily, available) {
  const style = tokens(id);
  const family = configuredFamily || (fixed ? style.fixedFontFamily : style.fontFamily) || applicationFamily;
  const fallbacks = fixed ? null : style.fontFallbacks;
  if (!fallbacks || !fallbacks.length || !available || family !== fallbacks[0])
    return family;
  for (const candidate of fallbacks) {
    if (available.indexOf(candidate) !== -1)
      return candidate;
  }
  return fallbacks[fallbacks.length - 1];
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
