.pragma library

// Geometry, color and path helpers for the Keycap UI style.
// A keycap is an ink outline, a thin cream ring, a fill and a hard shadow
// straight down. Pressing sinks the face into its shadow.

function clamp(value, low, high) {
  return Math.max(low, Math.min(high, value));
}

// Vertical offset of the face from its rest position: lifted while hovered,
// sunk towards the shadow while pressed (or latched down).
function sink(depth, pressedDepth, hoverLift, down, hovered) {
  const d = Math.max(0, Number(depth) || 0);
  if (d === 0)
    return 0;
  if (down)
    return d - clamp(Number(pressedDepth) || 0, 0, d);
  if (hovered)
    return -Math.max(0, Number(hoverLift) || 0);
  return 0;
}

// Visible shadow below the face for a given sink.
function shadowOffset(depth, faceSink) {
  return Math.max(0, (Number(depth) || 0) - (Number(faceSink) || 0));
}

function mix(a, b, t) {
  const k = clamp(Number(t) || 0, 0, 1);
  return {
    "r": a.r + (b.r - a.r) * k,
    "g": a.g + (b.g - a.g) * k,
    "b": a.b + (b.b - a.b) * k,
    "a": (a.a === undefined ? 1 : a.a) + ((b.a === undefined ? 1 : b.a) - (a.a === undefined ? 1 : a.a)) * k
  };
}

// Relative luminance (sRGB, components 0..1).
function luminance(c) {
  const channel = v => v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

function contrast(a, b) {
  const la = luminance(a);
  const lb = luminance(b);
  return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05);
}

// The candidate that reads best on top of `fill`.
function readableOn(fill, dark, light) {
  return contrast(fill, dark) >= contrast(fill, light) ? dark : light;
}

// Dark text and details: the surface pushed most of the way to black.
function shade(surface, strength) {
  const c = mix(surface, {
                  "r": 0,
                  "g": 0,
                  "b": 0,
                  "a": 1
                }, strength === undefined ? 0.72 : strength);
  c.a = 1;
  return c;
}

// Outline and hard-shadow ink. On light surfaces it is the shade; on dark ones the
// surface pushed towards white instead, or outlines and shadows vanish into the fills.
function ink(surface, strength) {
  if (luminance(surface) >= 0.18)
    return shade(surface, strength);
  const c = mix(surface, {
                  "r": 1,
                  "g": 1,
                  "b": 1,
                  "a": 1
                }, strength === undefined ? 0.62 : strength);
  c.a = 1;
  return c;
}

// The cream ring just inside the outline, tinted towards the fill.
function ring(fill, cream, tint) {
  const c = mix(cream, fill, tint === undefined ? 0.25 : tint);
  c.a = 1;
  return c;
}

// Deterministic small tilt for stickers, in degrees within [-max, max].
// Never exactly zero so a sticker always looks hand placed.
function tilt(seed, max) {
  const text = String(seed || "");
  let hash = 7;
  for (let i = 0; i < text.length; i++)
    hash = (hash * 31 + text.charCodeAt(i)) % 1000003;
  const limit = Math.abs(Number(max) || 0);
  if (limit === 0)
    return 0;
  const unit = (hash % 2001) / 1000 - 1; // -1..1
  const value = Math.round(unit * limit * 10) / 10;
  if (value === 0)
    return hash % 2 === 0 ? limit / 2 : -limit / 2;
  return value;
}

// Lit segments of a level meter. Any non-zero level lights one segment.
function levelSegments(level, count) {
  const n = Math.max(0, Math.round(Number(count) || 0));
  const value = Number(level);
  if (!isFinite(value) || value <= 0 || n === 0)
    return 0;
  return clamp(Math.ceil(value * n - 1e-9), 1, n);
}

// Badge text for a counter: empty for nothing, "9+" above the maximum.
function countLabel(count, max) {
  const n = Math.max(0, Math.floor(Number(count) || 0));
  const limit = Math.max(1, Math.floor(Number(max) || 9));
  if (n === 0)
    return "";
  return n > limit ? limit + "+" : String(n);
}

// Split a clock line into flip tiles (letters and digits) and separators.
function flipSegments(text) {
  const source = String(text === undefined || text === null ? "" : text);
  const segments = [];
  const isTile = ch => /[0-9A-Za-zÀ-￿]/.test(ch);
  for (const ch of source) {
    const tile = isTile(ch);
    const last = segments[segments.length - 1];
    if (last && last.tile === tile)
      last.text += ch;
    else
      segments.push({
                      "text": ch,
                      "tile": tile
                    });
  }
  return segments;
}

// How a workspace key is drawn.
function workspaceKey(focused, urgent, occupied) {
  if (focused)
    return {
      "kind": "focused",
      "raised": true,
      "hollow": false,
      "depthScale": 1
    };
  if (urgent)
    return {
      "kind": "urgent",
      "raised": true,
      "hollow": false,
      "depthScale": 1
    };
  if (occupied)
    return {
      "kind": "occupied",
      "raised": true,
      "hollow": false,
      "depthScale": 0.5
    };
  return {
    "kind": "empty",
    "raised": false,
    "hollow": true,
    "depthScale": 0
  };
}

// Index of the lit dot for a power profile (saver, balanced, performance).
function profileDot(profile) {
  switch (String(profile)) {
  case "power-saver":
  case "saver":
    return 0;
  case "performance":
    return 2;
  default:
    return 1;
  }
}

function _n(v) {
  return Math.round(v * 100) / 100;
}

function _arc(r, x, y, sweep) {
  return "A " + _n(r) + " " + _n(r) + " 0 0 " + sweep + " " + _n(x) + " " + _n(y) + " ";
}

// Rounded rectangle with semicircle notches cut into the top and bottom edges
// at notchX: a ticket stub. Traced clockwise.
function ticketPath(w, h, r, notchX, notchR) {
  const rad = clamp(r, 0, Math.min(w, h) / 2);
  const nr = clamp(notchR, 0, h / 4);
  const nx = clamp(notchX, rad + nr, w - rad - nr);
  let p = "M " + _n(rad) + " 0 ";
  if (nr > 0)
    p += "L " + _n(nx - nr) + " 0 " + _arc(nr, nx + nr, 0, 0);
  p += "L " + _n(w - rad) + " 0 " + _arc(rad, w, rad, 1);
  p += "L " + _n(w) + " " + _n(h - rad) + " " + _arc(rad, w - rad, h, 1);
  if (nr > 0)
    p += "L " + _n(nx + nr) + " " + _n(h) + " " + _arc(nr, nx - nr, h, 0);
  p += "L " + _n(rad) + " " + _n(h) + " " + _arc(rad, 0, h - rad, 1);
  p += "L 0 " + _n(rad) + " " + _arc(rad, rad, 0, 1) + "Z";
  return p;
}

// Luggage tag: pointed on the left, rounded on the right.
function tagPath(w, h, r, point) {
  const rad = clamp(r, 0, Math.min(w, h) / 2);
  const pt = clamp(point, 0, w / 2);
  return "M " + _n(pt) + " 0 L " + _n(w - rad) + " 0 " + _arc(rad, w, rad, 1) + "L " + _n(w) + " " + _n(h - rad) + " " + _arc(rad, w - rad, h, 1) + "L " + _n(pt) + " " + _n(h) + " L 0 " + _n(h / 2) + " Z";
}

// Embossed label tape with fishtail notches at both ends.
function tapePath(w, h, notch) {
  const n = clamp(notch, 0, w / 4);
  return "M 0 0 L " + _n(w) + " 0 L " + _n(w - n) + " " + _n(h / 2) + " L " + _n(w) + " " + _n(h) + " L 0 " + _n(h) + " L " + _n(n) + " " + _n(h / 2) + " Z";
}

// Receipt: rounded top corners and a zig-zag torn bottom edge.
function receiptPath(w, h, r, tooth) {
  const rad = clamp(r, 0, Math.min(w, h) / 2);
  const t = clamp(tooth, 1, h / 3);
  const teeth = Math.max(1, Math.round(w / (t * 2)));
  const step = w / teeth;
  let p = "M " + _n(rad) + " 0 L " + _n(w - rad) + " 0 " + _arc(rad, w, rad, 1) + "L " + _n(w) + " " + _n(h) + " ";
  for (let i = teeth - 1; i >= 0; i--) {
    p += "L " + _n(i * step + step / 2) + " " + _n(h - t) + " ";
    p += "L " + _n(i * step) + " " + _n(h) + " ";
  }
  p += "L 0 " + _n(rad) + " " + _arc(rad, rad, 0, 1) + "Z";
  return p;
}

// Postage stamp: a rectangle whose edges are bitten by semicircle perforations.
function stampPath(w, h, bite) {
  const b = clamp(bite, 0.5, Math.min(w, h) / 6);
  const edge = (from, to, fixed, horizontal, count) => {
    let s = "";
    const length = to - from;
    const step = length / count;
    for (let i = 0; i < count; i++) {
      const c = from + step * (i + 0.5);
      const a = c - b * Math.sign(length);
      const e = c + b * Math.sign(length);
      if (horizontal)
        s += "L " + _n(a) + " " + _n(fixed) + " " + _arc(b, e, fixed, 0);
      else
        s += "L " + _n(fixed) + " " + _n(a) + " " + _arc(b, fixed, e, 0);
    }
    return s;
  };
  const across = Math.max(1, Math.floor(w / (b * 4)));
  const down = Math.max(1, Math.floor(h / (b * 4)));
  return "M 0 0 " + edge(0, w, 0, true, across) + "L " + _n(w) + " 0 " + edge(0, h, w, false, down) + "L " + _n(w) + " " + _n(h) + " " + edge(w, 0, h, true, across) + "L 0 " + _n(h) + " " + edge(h, 0, 0, false, down) + "Z";
}
