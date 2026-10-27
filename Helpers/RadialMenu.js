.pragma library

// Desktop radial menu (Fly-Pie style marking menu): item tree, ring geometry,
// pointer hit testing and the gesture/click state machine. No QML dependencies,
// see Tests/tst_radialmenu.qml.
//
// Angles are in degrees, clockwise, 0 pointing up. Screen offsets use y down.

var maxItemsPerRing = 12;
var maxDepth = 4;

// Built-in actions. `arg` says what the item's `arg` field holds.
var actions = {
  "editDesktop": { "labelKey": "radial-menu.actions.edit-desktop", "icon": "layout-dashboard", "arg": "" },
  "settings": { "labelKey": "radial-menu.actions.settings", "icon": "settings", "arg": "" },
  // Opens the Right-click menu settings tab, to edit this menu
  "editRadialMenu": { "labelKey": "radial-menu.actions.edit-radial-menu", "icon": "pencil", "arg": "" },
  "wallpaper": { "labelKey": "radial-menu.actions.wallpaper", "icon": "photo", "arg": "command" },
  "lock": { "labelKey": "radial-menu.actions.lock", "icon": "lock", "arg": "" },
  "sessionMenu": { "labelKey": "radial-menu.actions.session-menu", "icon": "power", "arg": "" },
  "launcher": { "labelKey": "radial-menu.actions.launcher", "icon": "search", "arg": "" },
  "controlCenter": { "labelKey": "radial-menu.actions.control-center", "icon": "adjustments-horizontal", "arg": "" },
  "app": { "labelKey": "radial-menu.actions.app", "icon": "app-window", "arg": "app" },
  "command": { "labelKey": "radial-menu.actions.command", "icon": "terminal", "arg": "command" },
  "uiStyle": { "labelKey": "radial-menu.actions.ui-style", "icon": "palette", "arg": "style" },
  // Folder of every UI style, filled in when the menu opens (see expandItems)
  "uiStyles": { "labelKey": "radial-menu.actions.ui-styles", "icon": "palette", "arg": "" },
  "darkMode": { "labelKey": "radial-menu.actions.dark-mode", "icon": "sun-moon", "arg": "" },
  "nightLight": { "labelKey": "radial-menu.actions.night-light", "icon": "moon", "arg": "" },
  "doNotDisturb": { "labelKey": "radial-menu.actions.do-not-disturb", "icon": "bell-off", "arg": "" },
  "folder": { "labelKey": "radial-menu.actions.folder", "icon": "folder", "arg": "" }
};

function actionIds() {
  return Object.keys(actions);
}

function isFolder(item) {
  return !!item && item.action === "folder";
}

function str(value) {
  return typeof value === "string" ? value : "";
}

// Clean a saved tree: unknown actions and malformed entries are dropped, rings are
// capped at maxItemsPerRing and nesting at maxDepth. Always returns fresh objects.
function normalizeItems(items, depth) {
  const level = depth || 0;
  if (!Array.isArray(items) && !(items && typeof items.length === "number"))
    return [];
  const result = [];
  for (let i = 0; i < items.length && result.length < maxItemsPerRing; i++) {
    const raw = items[i];
    if (!raw || typeof raw !== "object" || !Object.prototype.hasOwnProperty.call(actions, raw.action))
      continue;
    const item = {
      "action": raw.action,
      "label": str(raw.label),
      "labelKey": str(raw.labelKey),
      "icon": str(raw.icon),
      "arg": str(raw.arg)
    };
    if (raw.action === "folder") {
      if (level + 1 >= maxDepth)
        continue;
      item.children = normalizeItems(raw.children, level + 1);
    }
    result.push(item);
  }
  return result;
}

// Replace generated folders with their contents: each "uiStyles" item becomes a folder
// with one "uiStyle" item per entry of `styles` ([{ key, labelKey }], UiStyles.choices()),
// so styles added later show up without editing the saved tree.
function expandItems(items, styles) {
  return (items || []).map(item => {
    if (item.action === "uiStyles") {
      return {
        "action": "folder",
        "label": item.label,
        "labelKey": item.label ? "" : actions.uiStyles.labelKey,
        "icon": item.icon || actions.uiStyles.icon,
        "arg": "",
        "children": (styles || []).slice(0, maxItemsPerRing).map(style => ({
                                                                         "action": "uiStyle",
                                                                         "label": "",
                                                                         "labelKey": style.labelKey || "",
                                                                         "icon": "",
                                                                         "arg": style.key
                                                                       }))
      };
    }
    if (isFolder(item))
      return Object.assign({}, item, { "children": expandItems(item.children, styles) });
    return item;
  });
}

// The ring shown at `path` (indices from the root). Invalid paths give [].
function itemsAt(items, path) {
  let ring = items || [];
  const steps = path || [];
  for (let i = 0; i < steps.length; i++) {
    const item = ring[steps[i]];
    if (!isFolder(item))
      return [];
    ring = item.children || [];
  }
  return ring;
}

function iconFor(item) {
  if (!item)
    return "";
  if (item.icon)
    return item.icon;
  const action = actions[item.action];
  return action ? action.icon : "";
}

// Translation key for the label, or "" when the item has its own text (or is an
// app, whose name comes from its desktop entry).
function labelKeyFor(item) {
  if (!item || item.label)
    return "";
  if (item.labelKey)
    return item.labelKey;
  // A style item is named after its style (options.ui-style.<id>)
  if (item.action === "uiStyle" && item.arg)
    return "options.ui-style." + item.arg;
  const action = actions[item.action];
  return action && item.action !== "app" ? action.labelKey : "";
}

// ---------------------------------------------------------------------------
// Geometry

function normalizeAngle(angle) {
  const a = angle % 360;
  return a < 0 ? a + 360 : a;
}

function angleOf(dx, dy) {
  return normalizeAngle(Math.atan2(dx, -dy) * 180 / Math.PI);
}

function sliceAngle(count) {
  return count > 0 ? 360 / count : 360;
}

// Center direction of wedge `index`; the first item points straight up
function itemAngle(index, count) {
  return normalizeAngle(index * sliceAngle(count));
}

function wedgeIndex(angle, count) {
  if (count <= 0)
    return -1;
  const slice = sliceAngle(count);
  return Math.floor(normalizeAngle(angle + slice / 2) / slice) % count;
}

// Wedge under an offset from the ring center. -1 inside the dead zone and beyond
// maxRadius (pass Infinity for direction-only gestures).
function hitTest(dx, dy, count, deadZone, maxRadius) {
  const distance = Math.sqrt(dx * dx + dy * dy);
  if (count <= 0 || distance < deadZone)
    return -1;
  if (maxRadius !== undefined && maxRadius !== null && distance > maxRadius)
    return -1;
  return wedgeIndex(angleOf(dx, dy), count);
}

function polar(angle, radius) {
  const rad = angle * Math.PI / 180;
  return { "x": radius * Math.sin(rad), "y": -radius * Math.cos(rad) };
}

// Item anchor points around the center, one per wedge
function layout(count, radius) {
  const result = [];
  for (let i = 0; i < count; i++) {
    const angle = itemAngle(i, count);
    const p = polar(angle, radius);
    result.push({ "index": i, "angle": angle, "x": p.x, "y": p.y });
  }
  return result;
}

// Outline of an annular wedge with a constant-width gap between neighbours, shrunk by
// `inset` on every side (stroke it with width 2 * inset to round the corners).
// Points are offsets from the ring center. Null when the wedge would vanish.
function wedgeShape(index, count, innerRadius, outerRadius, gap, inset) {
  const pad = (gap || 0) / 2 + (inset || 0);
  const inner = innerRadius + (inset || 0);
  const outer = outerRadius - (inset || 0);
  if (count <= 0 || outer <= inner || inner <= pad)
    return null;
  const center = itemAngle(index, count);
  const half = sliceAngle(count) / 2;
  const outerHalf = count === 1 ? 180 - Math.asin(pad / outer) * 180 / Math.PI : half - Math.asin(pad / outer) * 180 / Math.PI;
  const innerHalf = count === 1 ? 180 - Math.asin(pad / inner) * 180 / Math.PI : half - Math.asin(pad / inner) * 180 / Math.PI;
  if (outerHalf <= 0 || innerHalf <= 0)
    return null;
  return {
    "outerStart": polar(center - outerHalf, outer),
    "outerEnd": polar(center + outerHalf, outer),
    "innerEnd": polar(center + innerHalf, inner),
    "innerStart": polar(center - innerHalf, inner),
    "outerRadius": outer,
    "innerRadius": inner,
    "outerLarge": outerHalf * 2 > 180,
    "innerLarge": innerHalf * 2 > 180,
    "centerAngle": center
  };
}

// Keep a ring of `radius` (plus margin) fully on a width x height screen
function clampCenter(x, y, width, height, radius, margin) {
  const reach = radius + (margin || 0);
  const clampAxis = (value, size) => size <= reach * 2 ? size / 2 : Math.max(reach, Math.min(size - reach, value));
  return { "x": clampAxis(x, width), "y": clampAxis(y, height) };
}

// ---------------------------------------------------------------------------
// Pointer state machine
//
// state: { path, centers, hovered, held, pressX, pressY, dragged }
//   path     indices of the opened folders
//   centers  ring center per level (centers.length === path.length + 1)
//   held     the opening button is still down (gesture mode)
//   dragged  the pointer left the drag threshold while held
//
// Selection is by direction only: everything outside the dead zone belongs to a wedge,
// however far from the ring, so the whole screen is the click area.
//
// opts: { width, height, deadZone, descendRadius, dragThreshold, reach, margin, itemRadius }
//   descendRadius distance at which a held drag over a folder opens it
//   itemRadius    where keyboard-picked folders open their sub-ring
//   reach         ring extent used to keep centers on screen

function open(x, y, opts) {
  const c = clampCenter(x, y, opts.width, opts.height, opts.reach, opts.margin);
  return { "path": [], "centers": [c], "hovered": -1, "held": true, "pressX": x, "pressY": y, "dragged": false };
}

function currentCenter(state) {
  return state.centers[state.centers.length - 1];
}

function copy(state, changes) {
  const next = {
    "path": state.path.slice(),
    "centers": state.centers.slice(),
    "hovered": state.hovered,
    "held": state.held,
    "pressX": state.pressX,
    "pressY": state.pressY,
    "dragged": state.dragged
  };
  for (const key in changes)
    next[key] = changes[key];
  return next;
}

function descend(state, index, center, opts) {
  const c = clampCenter(center.x, center.y, opts.width, opts.height, opts.reach, opts.margin);
  return copy(state, { "path": state.path.concat([index]), "centers": state.centers.concat([c]), "hovered": -1 });
}

// Up one level; null when already at the root (the menu should close)
function back(state) {
  if (state.path.length === 0)
    return null;
  return copy(state, { "path": state.path.slice(0, -1), "centers": state.centers.slice(0, -1), "hovered": -1 });
}

function hoverAt(state, x, y, items, opts) {
  const c = currentCenter(state);
  const ring = itemsAt(items, state.path);
  return hitTest(x - c.x, y - c.y, ring.length, opts.deadZone, Infinity);
}

// Pointer moved. While held, crossing descendRadius over a folder opens it centered
// at the pointer so the stroke can continue into the sub-ring.
function move(state, x, y, items, opts) {
  let next = copy(state, {});
  if (state.held && !state.dragged) {
    const dx = x - state.pressX;
    const dy = y - state.pressY;
    next.dragged = Math.sqrt(dx * dx + dy * dy) >= opts.dragThreshold;
  }
  next.hovered = hoverAt(next, x, y, items, opts);
  if (next.held && next.dragged && next.hovered >= 0) {
    const ring = itemsAt(items, next.path);
    const item = ring[next.hovered];
    const c = currentCenter(next);
    const distance = Math.sqrt((x - c.x) * (x - c.x) + (y - c.y) * (y - c.y));
    if (isFolder(item) && distance >= opts.descendRadius)
      next = descend(next, next.hovered, { "x": x, "y": y }, opts);
  }
  return next;
}

// Result of release/click: { state, activate } — activate is the picked leaf item;
// state null means close the menu.
function release(state, x, y, items, opts) {
  if (!state.held)
    return { "state": state, "activate": null };
  const moved = move(state, x, y, items, opts);
  const settled = copy(moved, { "held": false });
  if (!moved.dragged || moved.hovered < 0)
    return { "state": settled, "activate": null };
  const item = itemsAt(items, moved.path)[moved.hovered];
  if (isFolder(item))
    return { "state": descend(settled, moved.hovered, { "x": x, "y": y }, opts), "activate": null };
  return { "state": null, "activate": item };
}

// Click in click mode: the center goes back (or closes at the root); anywhere else
// picks the wedge in that direction, and a folder opens its sub-ring at the click.
function click(state, x, y, items, opts) {
  const c = currentCenter(state);
  const ring = itemsAt(items, state.path);
  const index = hitTest(x - c.x, y - c.y, ring.length, opts.deadZone, Infinity);
  if (index < 0)
    return { "state": back(state), "activate": null };
  return pick(state, index, items, opts, { "x": x, "y": y });
}

// Pick wedge `index` of the current ring. A folder opens at `at` (the click), or at the
// item's anchor when picked from the keyboard.
function pick(state, index, items, opts, at) {
  const ring = itemsAt(items, state.path);
  const item = ring[index];
  if (!item)
    return { "state": state, "activate": null };
  if (isFolder(item)) {
    const c = currentCenter(state);
    const p = polar(itemAngle(index, ring.length), opts.itemRadius || 0);
    const center = at || { "x": c.x + p.x, "y": c.y + p.y };
    return { "state": descend(copy(state, { "held": false }), index, center, opts), "activate": null };
  }
  return { "state": null, "activate": item };
}

// The way down to the current ring: one link per opened folder, from the parent ring's
// center to the child's, with the folder item that was picked.
function trail(state, items) {
  if (!state)
    return [];
  const links = [];
  for (let i = 0; i < state.path.length; i++) {
    links.push({
      "from": state.centers[i],
      "to": state.centers[i + 1],
      "item": itemsAt(items, state.path.slice(0, i))[state.path[i]] || null
    });
  }
  return links;
}

// ---------------------------------------------------------------------------
// Tree editing (settings UI). All return a new tree.

function clone(items) {
  return normalizeItems(items, 0);
}

function withRing(items, path, edit) {
  const tree = clone(items);
  if (!path || path.length === 0)
    return edit(tree) || tree;
  const parent = itemsAt(tree, path.slice(0, -1))[path[path.length - 1]];
  if (!isFolder(parent))
    return tree;
  parent.children = edit(parent.children || []) || parent.children;
  return tree;
}

function addItem(items, path, item) {
  return withRing(items, path, ring => {
    if (ring.length < maxItemsPerRing)
      ring.push(item);
    return ring;
  });
}

function removeItem(items, path, index) {
  return withRing(items, path, ring => {
    ring.splice(index, 1);
    return ring;
  });
}

function moveItem(items, path, index, delta) {
  return withRing(items, path, ring => {
    const target = index + delta;
    if (index < 0 || index >= ring.length || target < 0 || target >= ring.length)
      return ring;
    const moved = ring.splice(index, 1)[0];
    ring.splice(target, 0, moved);
    return ring;
  });
}

function updateItem(items, path, index, changes) {
  return withRing(items, path, ring => {
    if (!ring[index])
      return ring;
    for (const key in changes)
      ring[index][key] = changes[key];
    if (ring[index].action === "folder" && !ring[index].children)
      ring[index].children = [];
    if (ring[index].action !== "folder")
      delete ring[index].children;
    return ring;
  });
}

// Flatten the tree for a list editor: one row per item with its ring path and depth
function flatten(items) {
  const rows = [];
  const walk = (ring, path) => {
    for (let i = 0; i < ring.length; i++) {
      rows.push({ "path": path, "index": i, "depth": path.length, "item": ring[i], "count": ring.length });
      if (isFolder(ring[i]))
        walk(ring[i].children || [], path.concat([i]));
    }
  };
  walk(normalizeItems(items, 0), []);
  return rows;
}

// ---------------------------------------------------------------------------
// Per-style look. A UI style sets `tokens.radialMenu` (see Helpers/UiStyles.js),
// at minimum `{ "shape": ... }`; the shape preset fills the rest.

var baseVisual = {
  "shape": "segment",
  "innerRadius": 50,
  "outerRadius": 130,
  "itemRadius": 90,
  "gap": 6,
  "cornerRadius": 12,
  "borderWidth": 0,
  "shadowX": 0,
  "shadowY": 0,
  "shadowOpacity": 0,
  "iconSize": 20,
  "centerRadius": 42,
  "centerShape": "circle",
  "hoverScale": 1.05,
  "hoverLift": 6,
  "pressDepth": 0,
  "tilt": 0,
  "openScale": 0.4,
  "openRotation": 0,
  "stagger": 18,
  "easing": "OutQuint",
  "fillOpacity": 1,
  "keylineWidth": 0,
  "colors": {
    "fill": "surfaceVariant",
    "onFill": "onSurfaceVariant",
    "hover": "primary",
    "onHover": "onPrimary",
    "center": "surface",
    "onCenter": "onSurface",
    "outline": "outline",
    "shadow": "shadow",
    "keyline": "surface"
  }
};

var shapePresets = {
  // Material 3: tonal rounded segments, filled primary on hover
  "segment": {},
  // Chunky keycaps: thick ink outline and a hard drop shadow; hovering lifts the
  // wedge off its shadow, pressing pushes it down
  "chunky": {
    "innerRadius": 48,
    "outerRadius": 128,
    "itemRadius": 88,
    "gap": 8,
    "cornerRadius": 6,
    "borderWidth": 2,
    "shadowX": 0,
    "shadowY": 4,
    "shadowOpacity": 1,
    "centerShape": "squircle",
    "hoverScale": 1,
    "hoverLift": 3,
    "pressDepth": 3,
    "tilt": 4,
    "openScale": 0.6,
    "openRotation": 0,
    "stagger": 22,
    "easing": "OutBack",
    "colors": {
      "fill": "surface",
      "onFill": "onSurface",
      "hover": "primary",
      "onHover": "onPrimary",
      "center": "secondary",
      "onCenter": "onSecondary",
      "outline": "ink",
      "shadow": "ink"
    }
  }
};

// How a spec color is resolved: a "#rrggbb" literal, "ink" (the theme surface pushed
// most of the way to black, for chunky outlines) or a theme role such as "onPrimary"
// which maps to ShellColors.mOnPrimary.
function colorSource(role) {
  const name = typeof role === "string" && role ? role : "primary";
  if (name.charAt(0) === "#")
    return { "kind": "literal", "value": name };
  // Outline ink of the style's kit (Style.kit.ink), light in dark schemes
  if (name === "ink")
    return { "kind": "ink" };
  return { "kind": "theme", "value": "m" + name.charAt(0).toUpperCase() + name.slice(1) };
}

function merge(target, source) {
  if (!source)
    return target;
  for (const key in source) {
    const value = source[key];
    if (value && typeof value === "object" && !Array.isArray(value))
      target[key] = merge(Object.assign({}, target[key] || {}), value);
    else if (value !== undefined)
      target[key] = value;
  }
  return target;
}

// User preferences from Settings.data.radialMenu, applied on top of the style's spec
var sizeRange = [0.6, 1.6];
var opacityRange = [0.3, 1];
// Spec fields that grow with the size preference; strokes, gaps and shadows stay put
var sizedFields = ["innerRadius", "outerRadius", "itemRadius", "centerRadius", "iconSize", "cornerRadius"];

function clamp(value, range, fallback) {
  const n = Number(value);
  return isFinite(n) ? Math.max(range[0], Math.min(range[1], n)) : fallback;
}

// The style's spec with the user's preferences ({ shape, size, opacity, animations }).
// shape "auto" (or unknown) keeps the style's own shape; everything else overrides it.
function visual(styleSpec, prefs) {
  const p = prefs || {};
  const own = styleSpec && Object.prototype.hasOwnProperty.call(shapePresets, styleSpec.shape) ? styleSpec.shape : "segment";
  const forced = p.shape && p.shape !== "auto" && Object.prototype.hasOwnProperty.call(shapePresets, p.shape) ? p.shape : "";
  const shape = forced || own;
  // A forced shape drops the style's own shape tweaks but keeps its colors
  const styleExtras = forced && forced !== own ? { "colors": (styleSpec || {}).colors } : (styleSpec || {});
  const spec = merge(merge(merge({}, baseVisual), shapePresets[shape]), styleExtras);
  spec.shape = shape;
  const size = clamp(p.size, sizeRange, 1);
  for (const field of sizedFields)
    spec[field] = spec[field] * size;
  spec.fillOpacity = spec.fillOpacity * clamp(p.opacity, opacityRange, 1);
  spec.animate = p.animations !== false;
  if (!spec.animate) {
    spec.stagger = 0;
    spec.openScale = 1;
    spec.openRotation = 0;
  }
  return spec;
}

// Delay before wedge `index` starts its open animation
function staggerDelay(index, count, stagger) {
  return count > 0 ? Math.max(0, index) * Math.max(0, stagger) : 0;
}
