.pragma library

// Presentation helpers shared by the per-style launcher views
// (Modules/Panels/Launcher/*LauncherView.qml). Free of QML singletons so
// the logic can be tested directly.

function clamp(value, low, high) {
  return Math.max(low, Math.min(high, value));
}

// How an entry's leading visual is drawn, in order of precedence:
// "string" (emoji or calculator text), "color" (clipboard swatch),
// "image" (clipboard picture), "glyph" (Tabler font icon), "app" (themed
// icon) and "letter" (first letter of the name when nothing else exists).
function iconKind(item, iconMode, imageFailed) {
  if (!item)
    return "letter";
  if (item.displayString)
    return "string";
  if (item.colorHex)
    return "color";
  if (item.isImage && !imageFailed)
    return "image";
  if (item.icon) {
    if (iconMode === "tabler" && item.isTablerIcon)
      return "glyph";
    return "app";
  }
  return "letter";
}

function letterFor(name) {
  const text = String(name || "").trim();
  return text ? text.charAt(0).toUpperCase() : "?";
}

// Index `delta` steps away from `current` in a list of `length`, wrapping.
// An unknown current index (-1) starts from the first entry.
function cycleIndex(current, delta, length) {
  if (!(length > 0))
    return -1;
  const from = current >= 0 && current < length ? current : (delta > 0 ? -1 : 0);
  return (((from + delta) % length) + length) % length;
}

// Corner radii of one segment in a connected group (Material 3 Expressive
// button groups and segmented lists). The ends of the group keep the outer
// radius, the joints get the small inner radius and the selected segment
// becomes fully round. `vertical` stacks the segments top to bottom.
function groupRadii(index, count, size, outer, inner, selected, vertical) {
  const full = Math.max(0, size / 2);
  const out = Math.min(outer, full);
  const inn = Math.min(inner, full);
  if (selected)
    return {
      "tl": full,
      "tr": full,
      "bl": full,
      "br": full
    };
  const first = index <= 0;
  const last = index >= count - 1;
  if (vertical)
    return {
      "tl": first ? out : inn,
      "tr": first ? out : inn,
      "bl": last ? out : inn,
      "br": last ? out : inn
    };
  return {
    "tl": first ? out : inn,
    "bl": first ? out : inn,
    "tr": last ? out : inn,
    "br": last ? out : inn
  };
}

// Width of each key in a row that splits `available` px between `count` keys
// with `gap` px between them, no wider than `maxWidth` and no narrower than
// `minWidth`.
function keyWidth(available, count, gap, minWidth, maxWidth) {
  if (!(count > 0))
    return 0;
  const share = (available - gap * (count - 1)) / count;
  return Math.floor(clamp(share, minWidth, Math.max(minWidth, maxWidth)));
}

// Grid cell for `columns` columns across `width`; `ratio` makes cells taller.
function gridCell(width, columns, ratio) {
  const cols = Math.max(1, Math.round(columns) || 1);
  const w = Math.max(0, width) / cols;
  const r = ratio > 0 ? ratio : 1;
  return {
    "width": w,
    "height": w * r
  };
}

// Row holding `index` in a list (one entry per row) or a grid.
function rowOf(index, isGrid, columns) {
  if (index < 0)
    return 0;
  return isGrid ? Math.floor(index / Math.max(1, columns)) : index;
}

// Top of the preview card next to the selected row, kept inside the panel.
function previewY(rowTop, panelTop, panelHeight, previewHeight, margin) {
  const low = panelTop + margin;
  const high = panelTop + panelHeight - previewHeight - margin;
  return Math.max(low, Math.min(rowTop, high));
}

// What the status line under the results shows: the result count, a
// "no results" note while searching, or the provider's empty message.
function footerState(count, searchText, emptyMessage) {
  if (count > 0)
    return {
      "kind": "count",
      "count": count
    };
  if (searchText)
    return {
      "kind": "empty",
      "count": 0
    };
  if (emptyMessage)
    return {
      "kind": "message",
      "count": 0
    };
  return {
    "kind": "none",
    "count": 0
  };
}

// Delay before the entry at `index` pops in: a short stagger down the
// first `cap` entries, so a fresh list cascades instead of blinking in.
function popDelay(index, step, cap) {
  if (!(index > 0))
    return 0;
  return Math.min(index, cap) * Math.max(0, step);
}

// Sticker tilt in degrees for a label, stable per text and within ±max.
function tiltFor(text, max) {
  const s = String(text || "");
  let h = 0;
  for (let i = 0; i < s.length; i++)
    h = (h * 31 + s.charCodeAt(i)) | 0;
  const m = Math.abs(Number(max) || 0);
  if (m === 0)
    return 0;
  // Spread across [-max, max] and never quite flat.
  const t = ((Math.abs(h) % 1000) / 999) * 2 - 1;
  const v = t * m;
  return Math.abs(v) < m / 3 ? (v < 0 ? -m / 3 : m / 3) : v;
}

// Leading glyph of the search field: a terminal prompt in command mode.
function searchGlyph(searchText) {
  return String(searchText || "").startsWith(">") ? "terminal-2" : "search";
}
