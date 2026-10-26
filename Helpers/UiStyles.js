.pragma library

// UI styles live in Styles/<id>/, one folder each. A folder's Definition.qml holds
// the style's label, appearance defaults, tokens and views; its other files are the
// control skins (Style.skinUrl()). Commons/UiStyleRegistry.qml finds the folders and
// keeps a map of id -> definition (see fromDefinition()). These helpers take that map,
// one definition or its tokens, so tests can load the real folders.
var defaultStyle = "material";

// Plain copy of a Definition.qml object.
function fromDefinition(object) {
  if (!object)
    return null;
  return JSON.parse(JSON.stringify({
                                     "labelKey": object.labelKey,
                                     "kit": object.kit || "",
                                     "settingsDefaults": object.settingsDefaults || {},
                                     "views": object.views || {},
                                     "barViews": object.barViews || {},
                                     "tokens": object.tokens
                                   }));
}

// Loads `<directory>/<id>/Definition.qml` (directory as a path or URL), or null.
function load(directory, id) {
  const component = Qt.createComponent(directory + "/" + id + "/Definition.qml");
  // 1 is Component.Ready, which a .pragma library can't name
  if (component.status !== 1) {
    console.warn("UiStyles: style \"" + id + "\" has no usable Definition.qml:", component.errorString());
    return null;
  }
  const object = component.createObject(null);
  const definition = fromDefinition(object);
  object.destroy();
  return definition && definition.tokens ? definition : null;
}

function loadAll(directory, ids) {
  const definitions = {};
  for (const id of ids) {
    const definition = load(directory, id);
    if (definition)
      definitions[id] = definition;
  }
  return definitions;
}

function resolveId(definitions, id) {
  return Object.prototype.hasOwnProperty.call(definitions, id) ? id : defaultStyle;
}

function definition(definitions, id) {
  return definitions[resolveId(definitions, id)] || null;
}

function choices(definitions) {
  return Object.keys(definitions).sort((a, b) => a === defaultStyle ? -1 : b === defaultStyle ? 1 : a.localeCompare(b)).map(id => ({ "key": id, "labelKey": definitions[id].labelKey }));
}

function view(definition, surface) {
  return definition && definition.views ? definition.views[surface] || "" : "";
}

// Style-specific face of a bar widget, or "" to keep the shared look.
function barView(definition, name) {
  const views = definition ? definition.barViews : null;
  return views && name && Object.prototype.hasOwnProperty.call(views, name) ? views[name] : "";
}

// Include preset families in the picker even when they are application-loaded
// fonts, which fc-list does not enumerate.
function fontFamilies(definitions) {
  return Object.keys(definitions).map(id => definitions[id].tokens?.fontFamily).filter((family, index, families) => family && families.indexOf(family) === index);
}

// `available` (optional) lists installed families. When the configured or
// preset family is the style's preferred font and it is missing, the style's
// `fontFallbacks` are tried in order; the last one is used regardless.
function fontFamily(tokens, configuredFamily, fixed, applicationFamily, available) {
  const family = configuredFamily || (fixed ? tokens.fixedFontFamily : tokens.fontFamily) || applicationFamily;
  const fallbacks = fixed ? null : tokens.fontFallbacks;
  if (!fallbacks || !fallbacks.length || !available || family !== fallbacks[0])
    return family;
  for (const candidate of fallbacks) {
    if (available.indexOf(candidate) !== -1)
      return candidate;
  }
  return fallbacks[fallbacks.length - 1];
}

// Slider shapes: "split" (Material: track split around a slim handle) or "knob"
// (round knob over one track).
function sliderGeometry(tokens, baseSize, heightRatio, scale) {
  const slider = tokens.slider;
  if (slider.shape === "split") {
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
function buttonGroupRadii(tokens, height, checked, isFirst, isLast) {
  const group = tokens.buttonGroup;
  if (!group)
    return null;
  const full = height / 2;
  const inner = Math.min(group.innerRadius, full);
  return { "left": checked || isFirst ? full : inner, "right": checked || isLast ? full : inner };
}

// Frosted glass: translucent panels and cards over the compositor blur.
// Null when the style has no glass look or it is turned off. `custom` holds the
// user's panelOpacity and surfaceOpacity; missing or invalid values use the style's.
function glass(tokens, enabled, custom) {
  const frosted = enabled ? tokens.frostedGlass : null;
  if (!frosted)
    return null;
  const pick = key => {
    const value = custom ? Number(custom[key]) : NaN;
    return isFinite(value) && custom[key] !== null && custom[key] !== "" ? Math.max(0, Math.min(1, value)) : frosted[key];
  };
  return { "panelOpacity": pick("panelOpacity"), "surfaceOpacity": pick("surfaceOpacity") };
}

// Panel background opacity before light-mode adaptation.
function panelOpacity(tokens, configured, glassEnabled, custom) {
  const frosted = glass(tokens, glassEnabled, custom);
  return frosted ? frosted.panelOpacity : configured;
}

// Filled fields keep their rounded shape on focus and use an outline for feedback.
function fieldShape(tokens, focused, cornerRadius) {
  const field = tokens.field;
  if (!field)
    return null;
  return {
    "radius": cornerRadius === undefined ? field.radius : cornerRadius,
    "borderWidth": focused ? field.focusBorderWidth : 0
  };
}

// Material 3 Expressive expandable card: the header stands alone when
// collapsed and joins the content as one connected card when expanded.
function expandableShape(tokens, expanded) {
  const shape = tokens.expandable;
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

// Toggle shapes: "pill" (Material: the handle grows when on and while pressed) or
// "track" (a fixed handle sliding along the track).
function toggleGeometry(tokens, baseSize, checked, pressed) {
  const toggle = tokens.toggle;
  if (toggle.shape === "pill") {
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

// Depth of a style's bar faces, limited by the slack between bar and capsule
// heights; 0 for styles without faces.
function barFaceDepth(tokens, barHeight, capsuleHeight, scale) {
  const preferred = tokens.faces ? Math.round(tokens.faces.barDepth * scale) : 0;
  if (preferred <= 0)
    return 0;
  const slack = Math.floor((Number(barHeight) - Number(capsuleHeight)) / 2) * 2;
  return Math.max(0, Math.min(preferred, Math.max(1, slack)));
}
