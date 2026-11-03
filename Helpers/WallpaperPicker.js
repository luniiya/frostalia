.pragma library

// Logic of the wallpaper picker (Modules/Panels/WallpaperPicker): search, color
// families, sorting, the carousel's geometry and the opening animation. Kept free
// of QML dependencies so it can be unit tested (Tests/tst_wallpaperpicker.qml).
//
// An entry is what the theming helper reports for an image (Tools/theming wallpapers):
// { path, name, ext, mtime, color: "#rrggbb" or null, thumb: path or null }

// ---------------------------------------------------------------------------
// Color families

// Swatches offered as filters, in hue order, then the neutrals. `swatch` is the
// color drawn for the chip, not a match target.
var families = [
      {
        "key": "red",
        "swatch": "#e5484d"
      },
      {
        "key": "orange",
        "swatch": "#f76b15"
      },
      {
        "key": "yellow",
        "swatch": "#f5d90a"
      },
      {
        "key": "green",
        "swatch": "#46a758"
      },
      {
        "key": "teal",
        "swatch": "#12a594"
      },
      {
        "key": "blue",
        "swatch": "#3e63dd"
      },
      {
        "key": "purple",
        "swatch": "#8e4ec6"
      },
      {
        "key": "pink",
        "swatch": "#d6409f"
      },
      {
        "key": "black",
        "swatch": "#111111"
      },
      {
        "key": "gray",
        "swatch": "#8b8b8b"
      },
      {
        "key": "white",
        "swatch": "#f4f4f4"
      }
    ];

// Upper hue bound (exclusive) of each chromatic family; red also covers >= 345
var hueBounds = [[15, "red"], [45, "orange"], [70, "yellow"], [160, "green"], [200, "teal"], [255, "blue"], [290, "purple"], [345, "pink"], [360, "red"]];

// Same threshold as the helper's dominant color (Tools/theming/src/wallpapers.rs)
var neutralChroma = 0.12;

function parseHex(hex) {
  const m = /^#?([0-9a-f]{6})$/i.exec(String(hex || ""));
  if (!m)
    return null;
  const n = parseInt(m[1], 16);
  return {
    "r": (n >> 16) & 255,
    "g": (n >> 8) & 255,
    "b": n & 255
  };
}

// { h: 0-360, s: 0-1, l: 0-1, c: chroma 0-1 } or null
function hsl(hex) {
  const rgb = parseHex(hex);
  if (!rgb)
    return null;
  const r = rgb.r / 255, g = rgb.g / 255, b = rgb.b / 255;
  const max = Math.max(r, g, b), min = Math.min(r, g, b);
  const c = max - min;
  const l = (max + min) / 2;
  let h = 0;
  if (c > 0) {
    if (max === r)
      h = 60 * ((((g - b) / c) % 6 + 6) % 6);
    else if (max === g)
      h = 60 * ((b - r) / c + 2);
    else
      h = 60 * ((r - g) / c + 4);
  }
  const s = c === 0 ? 0 : c / (1 - Math.abs(2 * l - 1));
  return {
    "h": h,
    "s": s,
    "l": l,
    "c": c
  };
}

// Family key of a color, or "" when there is no color yet
function family(hex) {
  const v = hsl(hex);
  if (!v)
    return "";
  if (v.c < neutralChroma)
    return v.l < 0.25 ? "black" : v.l > 0.75 ? "white" : "gray";
  for (let i = 0; i < hueBounds.length; i++) {
    if (v.h < hueBounds[i][0])
      return hueBounds[i][1];
  }
  return "red";
}

function familyIndex(key) {
  for (let i = 0; i < families.length; i++) {
    if (families[i].key === key)
      return i;
  }
  return families.length;
}

// { familyKey: number of entries } for the swatch badges
function familyCounts(entries) {
  const counts = {};
  for (const f of families)
    counts[f.key] = 0;
  for (const e of entries || []) {
    const key = family(e.color);
    if (key)
      counts[key]++;
  }
  return counts;
}

// ---------------------------------------------------------------------------
// Search, filter, sort

// Lowercase words of a file name or query; "_", "-" and "." separate words too
function words(text) {
  return String(text || "").toLowerCase().split(/[\s_\-.]+/).filter(w => w.length > 0);
}

// Every query word must start a word of the name or appear inside it
function matches(name, query) {
  const wanted = words(query);
  if (wanted.length === 0)
    return true;
  const haystack = words(name).join(" ");
  return wanted.every(w => haystack.indexOf(w) !== -1);
}

var sortModes = ["name", "date", "hue"];

// Natural, case-insensitive order ("wall2" before "wall10"); QML's JS engine has
// no Intl, so localeCompare() ignores its `numeric` option
function naturalCompare(a, b) {
  const pa = String(a).toLowerCase().match(/\d+|\D+/g) || [];
  const pb = String(b).toLowerCase().match(/\d+|\D+/g) || [];
  for (let i = 0; i < Math.min(pa.length, pb.length); i++) {
    const na = /^\d/.test(pa[i]), nb = /^\d/.test(pb[i]);
    const diff = na && nb ? parseInt(pa[i], 10) - parseInt(pb[i], 10) : pa[i].localeCompare(pb[i]);
    if (diff !== 0)
      return diff < 0 ? -1 : 1;
  }
  return pa.length - pb.length;
}

function compareNames(a, b) {
  return naturalCompare(a.name, b.name) || String(a.path).localeCompare(String(b.path));
}

// Hue order follows the swatches; uncolored entries go last
function hueKey(entry) {
  const v = hsl(entry.color);
  if (!v)
    return [families.length + 1, 0];
  const f = family(entry.color);
  const index = familyIndex(f);
  // Neutrals dark to light; colors by hue, red's wrap-around side first
  const within = v.c < neutralChroma ? v.l : (v.h >= 345 ? v.h - 360 : v.h);
  return [index, within];
}

function sorted(entries, mode) {
  const list = (entries || []).slice();
  if (mode === "date")
    list.sort((a, b) => (b.mtime || 0) - (a.mtime || 0) || compareNames(a, b));
  else if (mode === "hue")
    list.sort((a, b) => {
                const ka = hueKey(a), kb = hueKey(b);
                return ka[0] - kb[0] || ka[1] - kb[1] || compareNames(a, b);
              });
  else
    list.sort(compareNames);
  return list;
}

// Entries matching the query and color family ("" for any), in `mode` order
function filtered(entries, query, familyKey, mode) {
  const list = (entries || []).filter(e => matches(e.name, query) && (!familyKey || family(e.color) === familyKey));
  return sorted(list, mode);
}

function indexOfPath(list, path) {
  if (!path)
    return -1;
  for (let i = 0; i < list.length; i++) {
    if (list[i].path === path)
      return i;
  }
  return -1;
}

// Keeps the selection on the same image when the list changes, else the
// nearest valid index
function keepSelection(list, path, previousIndex) {
  const i = indexOfPath(list, path);
  if (i >= 0)
    return i;
  if (list.length === 0)
    return -1;
  return Math.max(0, Math.min(previousIndex, list.length - 1));
}

function step(index, delta, count) {
  if (count <= 0)
    return -1;
  return Math.max(0, Math.min(count - 1, (index < 0 ? 0 : index) + delta));
}

// Next color filter after `key` ("" is all colors), wrapping around
function nextFamily(key, delta) {
  const keys = [""].concat(families.map(f => f.key));
  const i = Math.max(0, keys.indexOf(key || ""));
  return keys[((i + delta) % keys.length + keys.length) % keys.length];
}

function nextSort(mode, delta) {
  const i = Math.max(0, sortModes.indexOf(mode));
  const n = sortModes.length;
  return sortModes[((i + (delta === undefined ? 1 : delta)) % n + n) % n];
}

// The search query after Backspace; with `word` (Ctrl) the last word goes
function backspace(query, word) {
  const q = String(query || "");
  if (!word)
    return q.slice(0, -1);
  return q.replace(/\s*\S+\s*$/, "");
}

// Whether a key's text should be typed into the search query
function typable(text) {
  return typeof text === "string" && text.length === 1 && text >= " " && text !== "\x7f";
}

// "PNG", "JPG", "GIF" ...
function badge(ext) {
  const e = String(ext || "").toUpperCase();
  return e === "JPEG" ? "JPG" : e;
}

// File name as shown under the selected card
function title(entry) {
  return entry ? String(entry.name || "") : "";
}

// ---------------------------------------------------------------------------
// Carousel geometry
//
// Cards sit on a line; `d` is a card's offset from the selection in cards (it is
// fractional while the carousel scrolls). The selected card is `centerWidth` wide
// and grows into place, the others are strips `stripWidth` wide.

// Distance from the center to a card's center
function offsetX(d, g) {
  const first = g.centerWidth / 2 + g.gap + g.stripWidth / 2;
  const a = Math.abs(d);
  const x = a <= 1 ? a * first : first + (a - 1) * (g.stripWidth + g.gap);
  return d < 0 ? -x : x;
}

// How many strips fit on each side of the selected card
function visibleHalf(availableWidth, g) {
  const room = availableWidth / 2 - g.centerWidth / 2 - g.gap;
  return Math.max(0, Math.floor((room + g.gap) / (g.stripWidth + g.gap)));
}

// Card at offset d: { x (center, relative to the carousel's center), width,
// height, focus (1 selected .. 0 strip), skew (horizontal shear factor), z, opacity }.
// g: { centerWidth, stripWidth, gap, height, centerHeight, skew, mirror, half }
//   skew:   shear of the strips (0 for none); the selected card is never sheared
//   mirror: strips lean away from the center on both sides (coverflow) instead of
//           all leaning the same way
//   half:   strips per side; the outermost one fades out
function card(d, g) {
  const a = Math.abs(d);
  const focus = Math.max(0, 1 - a);
  const lean = Math.min(1, a) * (g.skew || 0);
  const half = g.half === undefined ? 6 : g.half;
  return {
    "x": offsetX(d, g),
    "width": g.stripWidth + (g.centerWidth - g.stripWidth) * focus,
    "height": g.height + ((g.centerHeight || g.height) - g.height) * focus,
    "focus": focus,
    "skew": g.mirror && d < 0 ? -lean : lean,
    "z": 1000 - Math.round(a * 10),
    "opacity": a <= half ? 1 : Math.max(0, 1 - (a - half) * 2)
  };
}

// The carousel draws a fixed ring of 2 * half + 3 slots. Slot `slot` shows the
// card whose index is congruent to it modulo the ring size within the window
// around `center`, so a card keeps its slot while it is visible. -1 when that
// index is outside 0..count-1.
function slotIndex(slot, center, half, count) {
  const size = 2 * half + 3;
  const first = Math.round(center) - half - 1;
  const index = first + (((slot - first) % size) + size) % size;
  return index >= 0 && index < count ? index : -1;
}

function slotCount(half) {
  return 2 * half + 3;
}

// ---------------------------------------------------------------------------
// Opening animation
//
// `t` runs 0..1 once while the picker opens (WallpaperPickerPanel.intro). The
// selected card appears first, the strips then unfold out of it, nearest first, and
// the toolbar grows from a pill and fills in one control after another.

// Eased progress of a step that runs from `start` to `end` of the timeline
function phase(t, start, end) {
  const p = Math.max(0, Math.min(1, (t - start) / Math.max(0.0001, end - start)));
  return 1 - Math.pow(1 - p, 3);
}

// Like phase(), with a small overshoot at the end
function popPhase(t, start, end) {
  const p = Math.max(0, Math.min(1, (t - start) / Math.max(0.0001, end - start)));
  const c = 1.2;
  return 1 + (c + 1) * Math.pow(p - 1, 3) + c * Math.pow(p - 1, 2);
}

// A card's look (card()) at time t of the opening: { x, opacity, scale, skew }.
// The selected card pops in on its own; strips slide out from behind it.
function introCard(look, d, t, half) {
  if (t >= 1)
    return {
      "x": look.x,
      "opacity": look.opacity,
      "scale": 1,
      "skew": look.skew
    };
  const a = Math.abs(d);
  if (a < 0.5) {
    const p = Math.max(0, Math.min(1, t / 0.3));
    return {
      "x": look.x,
      "opacity": look.opacity * p,
      "scale": 0.82 + 0.18 * popPhase(t, 0, 0.38),
      "skew": look.skew
    };
  }
  const start = 0.2 + 0.4 * Math.min(1, (a - 1) / Math.max(1, half));
  const p = phase(t, start, start + 0.4);
  return {
    "x": look.x * p,
    "opacity": look.opacity * Math.min(1, p * 1.5),
    "scale": 0.9 + 0.1 * p,
    "skew": look.skew * p
  };
}

// The toolbar at time t: { opacity, grow (0 a pill .. 1 full width), lift (0..1
// of the drop it slides up from) }
function introBar(t) {
  return {
    "opacity": phase(t, 0.3, 0.42),
    "grow": phase(t, 0.32, 0.68),
    "lift": 1 - phase(t, 0.3, 0.6)
  };
}

// Control `index` of `count` in the toolbar: 0..1 (with overshoot) as it pops in
function introItem(t, index, count) {
  const start = 0.5 + 0.35 * index / Math.max(1, count);
  return popPhase(t, start, start + 0.18);
}

// ---------------------------------------------------------------------------
// Files

// file:// URL of an absolute path; each segment is percent-encoded, so names
// with "#", "?" or "%" load as files instead of being read as URL syntax
function fileUrl(path) {
  const p = String(path || "");
  if (!p.startsWith("/"))
    return "";
  return "file://" + p.split("/").map(encodeURIComponent).join("/");
}

// Merges helper updates ({ path, color, thumb }) into entries; returns a new array
function applyUpdates(entries, updates) {
  if (!updates || updates.length === 0)
    return entries;
  const byPath = {};
  for (const u of updates)
    byPath[u.path] = u;
  return entries.map(e => {
                       const u = byPath[e.path];
                       return u ? Object.assign({}, e, {
                                                  "color": u.color,
                                                  "thumb": u.thumb
                                                }) : e;
                     });
}
