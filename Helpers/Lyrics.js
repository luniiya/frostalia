.pragma library

// Synced lyrics: parsing (LRC files, Rufin's lyrics documents), word timing, and
// where each line sits in the gliding stack of the desktop lyrics widget.
// The look and the stack follow SekaiPop's lyrics widget (github.com/Blapples/SekaiPop,
// GPL-3.0), rewritten for Frostalia.
//
// A line is { start, end, text, words } with times in seconds. `words` is empty when
// the source only times whole lines; otherwise each word is { text, start, end, parts },
// where `parts` are its timed syllables ({ text, start, end }).

// Seconds of the last line when nothing says when it ends
const lastLineLength = 5;

function clamp01(v) {
  return Math.max(0, Math.min(1, v));
}

// ===== LRC =====

// "mm:ss.xx" (or "mm:ss", "mm:ss:xx") to seconds; NaN when it isn't a time
function lrcTime(stamp) {
  const m = /^(\d+):(\d{1,2})(?:[.:](\d{1,3}))?$/.exec(String(stamp).trim());
  if (!m)
    return NaN;
  const fraction = m[3] ? Number(m[3]) / Math.pow(10, m[3].length) : 0;
  return Number(m[1]) * 60 + Number(m[2]) + fraction;
}

// Parse an LRC file. Lines with several stamps repeat; "<mm:ss.xx>" word stamps
// (enhanced LRC) become word timing; [offset:ms] moves everything earlier.
function parseLrc(text) {
  const rows = String(text || "").split(/\r?\n/);
  let offset = 0;
  const lines = [];
  for (const row of rows) {
    const tag = /^\[offset:\s*([+-]?\d+)\s*\]/i.exec(row.trim());
    if (tag) {
      offset = Number(tag[1]) / 1000;
      continue;
    }
    const stamps = [];
    let rest = row.trim();
    let m;
    while ((m = /^\[([^\]]+)\]/.exec(rest))) {
      const t = lrcTime(m[1]);
      if (isNaN(t))
        break;
      stamps.push(t);
      rest = rest.slice(m[0].length);
    }
    if (stamps.length === 0)
      continue;
    const words = enhancedWords(rest);
    const plain = rest.replace(/<[^>]*>/g, "").replace(/\s+/g, " ").trim();
    for (const start of stamps)
      lines.push({
                   "start": start,
                   "end": NaN,
                   "text": plain,
                   "words": words.map(w => shiftWord(w, start - stamps[0]))
                 });
  }
  lines.sort((a, b) => a.start - b.start);
  for (const line of lines) {
    line.start = Math.max(0, line.start - offset);
    line.words = line.words.map(w => shiftWord(w, -offset));
  }
  return dropBlanks(fillEnds(lines));
}

function shiftWord(word, by) {
  return {
    "text": word.text,
    "start": word.start + by,
    "end": word.end + by,
    "parts": word.parts.map(p => ({
                                    "text": p.text,
                                    "start": p.start + by,
                                    "end": p.end + by
                                  }))
  };
}

// "<00:01.00>Some<00:01.40>thing <00:02.00>right<00:02.60>" to timed words
function enhancedWords(rest) {
  const re = /<([^>]+)>([^<]*)/g;
  const marks = [];
  let m;
  while ((m = re.exec(rest))) {
    const t = lrcTime(m[1]);
    if (!isNaN(t))
      marks.push({
                   "t": t,
                   "text": m[2]
                 });
  }
  const parts = [];
  for (let i = 0; i < marks.length; i++) {
    if (marks[i].text.trim() === "" && !/\s/.test(marks[i].text))
      continue;
    const end = i + 1 < marks.length ? marks[i + 1].t : NaN;
    parts.push({
                 "text": marks[i].text,
                 "start": marks[i].t,
                 "end": end
               });
  }
  return groupParts(parts);
}

// Syllables to words: a new word starts after whitespace
function groupParts(parts) {
  const words = [];
  let current = null;
  let gap = true;
  for (const part of parts) {
    const leading = /^\s/.test(part.text);
    const text = part.text.trim();
    if (text === "") {
      gap = true;
      continue;
    }
    if (!current || gap || leading) {
      current = {
        "text": "",
        "start": part.start,
        "end": part.end,
        "parts": []
      };
      words.push(current);
    }
    current.text += text;
    current.parts.push({
                         "text": text,
                         "start": part.start,
                         "end": part.end
                       });
    current.end = part.end;
    gap = /\s$/.test(part.text);
  }
  // A syllable with no end runs to the next one
  const flat = [];
  for (const w of words)
    for (const p of w.parts)
      flat.push(p);
  for (let i = 0; i < flat.length; i++) {
    if (isNaN(flat[i].end))
      flat[i].end = i + 1 < flat.length ? flat[i + 1].start : flat[i].start + 0.6;
  }
  for (const w of words)
    w.end = w.parts[w.parts.length - 1].end;
  return words;
}

// Lines without an end run to the next line (the last one for a few seconds)
// Lines with nothing to sing: empty, or only "♪" and the like
function isBlank(text) {
  return /^[\s♪♫♬♩~・….*\-–—]*$/.test(String(text || "").replace(/\uD83C[\uDFB5\uDFB6]/g, ""));
}

// Blank lines only mark where the line before them ends; once that is in its end,
// they go, so an intro or a break is a gap between lines
function dropBlanks(lines) {
  return lines.filter(line => !isBlank(line.text) || (line.words && line.words.length > 0 && !line.words.every(w => isBlank(w.text))));
}

function fillEnds(lines) {
  for (let i = 0; i < lines.length; i++) {
    const next = i + 1 < lines.length ? lines[i + 1].start : NaN;
    const lastWord = lines[i].words.length ? lines[i].words[lines[i].words.length - 1].end : NaN;
    if (!(lines[i].end > lines[i].start)) {
      if (!isNaN(next))
        lines[i].end = next;
      else
        lines[i].end = Math.max(lines[i].start + lastLineLength, isNaN(lastWord) ? 0 : lastWord);
    }
  }
  return lines;
}

// ===== Rufin =====

// UTF-8 byte offset to string index, for Rufin's cue byte ranges
function byteToIndex(text) {
  const map = [];
  let bytes = 0;
  for (let i = 0; i < text.length; i++) {
    const code = text.codePointAt(i);
    const size = code < 0x80 ? 1 : code < 0x800 ? 2 : code < 0x10000 ? 3 : 4;
    for (let b = 0; b < size; b++)
      map[bytes + b] = i;
    bytes += size;
    if (code >= 0x10000)
      i++;
  }
  map[bytes] = text.length;
  return map;
}

// The main voice's cue line: background vocals are left out
function mainCueLine(line, agents) {
  const roles = {};
  for (const agent of agents || [])
    roles[agent.id] = agent.role;
  const cueLines = line.cue_lines || [];
  for (const cueLine of cueLines)
    if (roles[cueLine.agent_id] !== "Background" && (cueLine.cues || []).length)
      return cueLine;
  return null;
}

// One Rufin lyrics line to { start, end, text, words }
function rufinLine(line, agents) {
  const text = String(line.text || "");
  const words = [];
  const cueLine = mainCueLine(line, agents);
  if (cueLine) {
    const index = byteToIndex(text);
    const parts = [];
    let previousEnd = -1;
    for (const cue of cueLine.cues) {
      const from = index[cue.byte_start];
      const to = index[cue.byte_end_exclusive];
      // Whitespace in the line between two cues splits words, as does whitespace in the cue
      const between = (from !== undefined && previousEnd >= 0) ? text.slice(previousEnd, from) : "";
      parts.push({
                   "text": (/\s/.test(between) ? " " : "") + String(cue.text || ""),
                   "start": cue.start_millis / 1000,
                   "end": cue.end_millis !== undefined && cue.end_millis !== null ? cue.end_millis / 1000 : NaN
                 });
      if (to !== undefined)
        previousEnd = to;
    }
    for (const w of groupParts(parts))
      words.push(w);
  }
  const start = line.start_millis !== undefined && line.start_millis !== null ? line.start_millis / 1000 : (words.length ? words[0].start : NaN);
  return {
    "start": start,
    "end": line.end_millis !== undefined && line.end_millis !== null ? line.end_millis / 1000 : NaN,
    "text": text.replace(/\s+/g, " ").trim(),
    "words": words
  };
}

// A /api/lyrics payload (or one event of /api/lyrics/events) to { state, id, lines }.
// state: "ready", "loading", "instrumental" or "empty".
function fromRufin(payload) {
  const p = payload || {};
  const state = ["ready", "loading", "instrumental", "empty"].indexOf(p.state) >= 0 ? p.state : "empty";
  const out = {
    "state": state,
    "id": p.id !== undefined ? p.id : null,
    "lines": []
  };
  if (state !== "ready" || !p.document)
    return out;
  const doc = p.document;
  const lines = [];
  for (const line of doc.lines || []) {
    const parsed = rufinLine(line, doc.agents);
    if (!isNaN(parsed.start))
      lines.push(parsed);
  }
  lines.sort((a, b) => a.start - b.start);
  out.lines = dropBlanks(fillEnds(lines));
  if (out.lines.length === 0)
    out.state = "empty";
  return out;
}

// Rufin's identity on MPRIS
function isRufin(identity, desktopEntry) {
  return /rufin/i.test(String(identity || "")) || /rufin/i.test(String(desktopEntry || ""));
}

// The Web Controller from Rufin's settings.json text: { enabled, url }
function rufinEndpoint(settingsText) {
  let web = null;
  try {
    web = JSON.parse(settingsText).web_controller;
  } catch (e) {
    return {
      "enabled": false,
      "url": ""
    };
  }
  if (!web)
    return {
      "enabled": false,
      "url": ""
    };
  let host = String(web.address || "127.0.0.1");
  if (host === "0.0.0.0" || host === "::")
    host = "127.0.0.1";
  if (host.indexOf(":") >= 0)
    host = "[" + host + "]";
  return {
    "enabled": web.enabled === true,
    "url": "http://" + host + ":" + (Number(web.port) || 1717)
  };
}

const base64Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

function base64Decode(input) {
  const clean = String(input || "").replace(/[^A-Za-z0-9+/]/g, "");
  let bits = 0;
  let value = 0;
  let out = "";
  for (let i = 0; i < clean.length; i++) {
    value = (value << 6) | base64Chars.indexOf(clean[i]);
    bits += 6;
    if (bits >= 8) {
      bits -= 8;
      out += String.fromCharCode((value >> bits) & 0xff);
    }
  }
  // The token is hex, so the bytes are plain ASCII
  return out;
}

// The Web Controller token from Rufin's secrets.json text ("" when there is none)
function rufinToken(secretsText) {
  try {
    const file = JSON.parse(secretsText);
    const value = (file.secrets || {})["web-controller:token"];
    if (!value)
      return "";
    return file.format === "config-base64" ? base64Decode(value) : String(value);
  } catch (e) {
    return "";
  }
}

// The JSON of a server-sent event "data:" line; null for other lines
function eventData(line) {
  const m = /^data:\s?(.*)$/.exec(String(line || ""));
  if (!m)
    return null;
  try {
    return JSON.parse(m[1]);
  } catch (e) {
    return null;
  }
}

// ===== LRCLIB =====

function lrclibGetUrl(title, artist, album, duration) {
  let url = "https://lrclib.net/api/get?track_name=" + encodeURIComponent(title) + "&artist_name=" + encodeURIComponent(artist);
  if (album)
    url += "&album_name=" + encodeURIComponent(album);
  if (duration > 0)
    url += "&duration=" + Math.round(duration);
  return url;
}

function lrclibSearchUrl(title, artist) {
  return "https://lrclib.net/api/search?track_name=" + encodeURIComponent(title) + "&artist_name=" + encodeURIComponent(artist);
}

// The best synced result of a search: closest in length, within a few seconds
function pickLrclib(results, duration) {
  let best = null;
  let bestDiff = Infinity;
  for (const r of results || []) {
    if (!r || !r.syncedLyrics)
      continue;
    const diff = duration > 0 && r.duration > 0 ? Math.abs(r.duration - duration) : 0;
    if (diff <= 4 && diff < bestDiff) {
      best = r;
      bestDiff = diff;
    }
  }
  return best;
}

// Whether an LRCLIB answer is final: found or not found, but not a network error or a
// server hiccup, which are worth asking again
function lrclibSettled(status) {
  return status >= 200 && status < 500;
}

// The searches to try for a track: by title and artist, then the title without
// "(feat. …)" and the first artist only, then the same as free text. Databases list
// featured artists in all sorts of ways.
function lrclibSearchUrls(title, artist) {
  const clean = cleanTitle(title);
  const bare = lookupTitle(title);
  const first = firstArtist(artist);
  const urls = [lrclibSearchUrl(clean, artist)];
  if (bare !== clean || first !== String(artist || "").trim())
    urls.push(lrclibSearchUrl(bare, first));
  urls.push("https://lrclib.net/api/search?q=" + encodeURIComponent((bare + " " + first).trim()));
  return urls;
}

// A title without its featured artists: "Song (feat. X)" → "Song"
function lookupTitle(title) {
  return cleanTitle(title).replace(/\s*[\[(（](?:feat\.?|ft\.?|featuring|with)\s[^\])）]*[\])）]/gi, "").replace(/\s+(?:feat\.?|ft\.?)\s.*$/i, "").trim();
}

// The first of several artists: "aespa, Ty Dolla $ign" → "aespa"
function firstArtist(artist) {
  return String(artist || "").split(/\s*(?:,|;|&|\/|\sx\s|\sfeat\.?\s|\sft\.?\s|\sand\s)\s*/i)[0].trim();
}

// Titles from video sites carry noise that no lyrics database has
function cleanTitle(title) {
  return String(title || "").replace(/\s*[\[(【](?:official|mv|m\/v|music video|lyrics?|audio|hd|4k)[^\])】]*[\])】]/gi, "").replace(/\s+/g, " ").trim();
}

// ===== Timing =====

// Index of the line that is on at `t` (the last one started), -1 before the first
function lineIndexAt(lines, t) {
  let lo = 0;
  let hi = lines.length - 1;
  let found = -1;
  while (lo <= hi) {
    const mid = (lo + hi) >> 1;
    if (lines[mid].start <= t) {
      found = mid;
      lo = mid + 1;
    } else {
      hi = mid - 1;
    }
  }
  return found;
}

function smooth(x) {
  const v = clamp01(x);
  return v * v * (3 - 2 * v);
}

// Where the stack is, as a fractional line index: it glides to the next line over
// the last `glide` seconds before that line starts.
function cursor(lines, t, glide) {
  const i = lineIndexAt(lines, t);
  if (i + 1 >= lines.length)
    return i;
  const g = Math.max(0.01, Math.min(glide, lines[i + 1].start - (i >= 0 ? lines[i].start : lines[i + 1].start - glide)));
  return i + smooth((t - (lines[i + 1].start - g)) / g);
}

// The words of a line with their times: the source's when it has them, otherwise
// the line's time shared out over the words by length.
// Words in brackets, "(oh oh)", are ad libs: drawn smaller and in the second colour, and
// the marker hops over them. Returns copies with `adlib` set.
function markAdlibs(words) {
  let open = false;
  return words.map(w => {
                     const text = String(w.text || "");
                     const starts = /^[(（]/.test(text);
                     const adlib = open || starts;
                     if (starts)
                       open = true;
                     if (/[)）][^\w]*$/.test(text))
                       open = false;
                     return Object.assign({}, w, {
                                            "adlib": adlib
                                          });
                   });
}

function tokens(line) {
  if (line.words && line.words.length)
    return markAdlibs(line.words);
  const texts = String(line.text || "").split(/\s+/).filter(s => s.length > 0);
  if (texts.length === 0)
    return [];
  const weights = texts.map(s => s.length + 1);
  const total = weights.reduce((a, b) => a + b, 0);
  // Sing over most of the line, not up to the very start of the next one
  const span = Math.max(0.3, Math.min(line.end - line.start, 0.85 * (line.end - line.start) + 0.3));
  const out = [];
  let at = line.start;
  for (let i = 0; i < texts.length; i++) {
    const length = span * weights[i] / total;
    out.push({
               "text": texts[i],
               "start": at,
               "end": at + length,
               "parts": []
             });
    at += length;
  }
  return markAdlibs(out);
}

// How much of a word has been sung at `t`, 0..1. Timed syllables fill in turn.
function sung(word, t) {
  if (!word.parts || word.parts.length === 0)
    return clamp01((t - word.start) / Math.max(0.05, word.end - word.start));
  let done = 0;
  let total = 0;
  for (const p of word.parts) {
    const weight = Math.max(1, p.text.length);
    total += weight;
    done += weight * clamp01((t - p.start) / Math.max(0.05, p.end - p.start));
  }
  return total > 0 ? done / total : 0;
}

// ===== The stack =====

// A line's pose by its distance `d` to the cursor (0 is the line that is on, -1 the one
// before, +1 the next): y in units of the font size, then scale, opacity and tilt.
// Smooth between the rows, flat past the ends.
const POSES = [
  {
    "d": -2,
    "y": -3.1,
    "scale": 0.42,
    "opacity": 0,
    "rotation": 4.8
  },
  {
    "d": -1,
    "y": -1.63,
    "scale": 0.58,
    "opacity": 0.28,
    "rotation": 2.4
  },
  {
    "d": 0,
    "y": 0,
    "scale": 1,
    "opacity": 1,
    "rotation": 0
  },
  {
    "d": 1,
    "y": 1.79,
    "scale": 0.66,
    "opacity": 0.55,
    "rotation": -2.4
  },
  {
    "d": 2,
    "y": 3.21,
    "scale": 0.46,
    "opacity": 0,
    "rotation": -4.8
  }
];

// The Material stack: evenly spaced, no tilt, the lines around the sung one smaller
// and dimmer
const CALM_POSES = [
  {
    "d": -2,
    "y": -2.9,
    "scale": 0.62,
    "opacity": 0,
    "rotation": 0
  },
  {
    "d": -1,
    "y": -1.5,
    "scale": 0.72,
    "opacity": 0.45,
    "rotation": 0
  },
  {
    "d": 0,
    "y": 0,
    "scale": 1,
    "opacity": 1,
    "rotation": 0
  },
  {
    "d": 1,
    "y": 1.5,
    "scale": 0.72,
    "opacity": 0.6,
    "rotation": 0
  },
  {
    "d": 2,
    "y": 2.9,
    "scale": 0.62,
    "opacity": 0,
    "rotation": 0
  }
];

function pose(d) {
  return blendPose(POSES, d);
}

function calmPose(d) {
  return blendPose(CALM_POSES, d);
}

function blendPose(table, d) {
  const first = table[0];
  const last = table[table.length - 1];
  if (d <= first.d)
    return Object.assign({}, first);
  if (d >= last.d)
    return Object.assign({}, last);
  for (let i = 0; i < table.length - 1; i++) {
    const a = table[i];
    const b = table[i + 1];
    if (d <= b.d) {
      const u = smooth((d - a.d) / (b.d - a.d));
      return {
        "d": d,
        "y": lerp(a.y, b.y, u),
        "scale": lerp(a.scale, b.scale, u),
        "opacity": lerp(a.opacity, b.opacity, u),
        "rotation": lerp(a.rotation, b.rotation, u)
      };
    }
  }
  return Object.assign({}, last);
}

function lerp(a, b, x) {
  return a + (b - a) * x;
}

// The scale that fits a line `naturalW` wide into `maxW`, never below 0.45
function fit(naturalW, maxW) {
  if (naturalW <= 0 || naturalW <= maxW)
    return 1;
  return Math.max(0.45, maxW / naturalW);
}

// The wave before a line starts: as the line climbs into place (`d` from 1 to 0) its
// words hop up one after another. 0..1 for word `i` of `count`.
function wave(d, i, count) {
  if (d <= -0.01 || d >= 1)
    return 0;
  const stagger = 0.13;
  return Math.sin(Math.PI * clamp01((1 - d) * (1 + stagger * (count - 1)) - i * stagger));
}

// ===== The marker =====
// A diamond that bounces from word to word over the words of the tune (not the ad libs),
// landing on each as it starts.

// Indexes of the words that are not ad libs (all of them when the line is only ad libs)
function mainIndexes(words) {
  const out = [];
  for (let i = 0; i < words.length; i++) {
    if (!words[i].adlib)
      out.push(i);
  }
  if (out.length === 0) {
    for (let i = 0; i < words.length; i++)
      out.push(i);
  }
  return out;
}

// The last of `words` started at `t`, -1 before the first
function wordAt(words, t) {
  let found = -1;
  for (let i = 0; i < words.length; i++) {
    if (words[i].start > t)
      break;
    found = i;
  }
  return found;
}

// How far the marker is on its hop from word k to word k + 1: 0 just landed on k,
// 1 landing on k + 1. The last word has no hop.
function hop(words, k, t) {
  if (k < 0 || k >= words.length - 1)
    return 0;
  const a = words[k].start;
  const b = words[k + 1].start;
  return b <= a ? 0 : clamp01((t - a) / (b - a));
}

// The arch of a hop: 0 on the ground, 1 at the top
function arch(p) {
  return 4 * p * (1 - p);
}

// The squash of a word as it starts: 1 on landing, 0 a moment later
function hit(word, t) {
  if (!word || t < word.start)
    return 0;
  return Math.max(0, 1 - (t - word.start) / 0.22);
}

// Before the first line or in a long break: how far the dots have counted, 0..1, and
// whether to show them. A break is a gap of at least `minGap` seconds.
function waiting(lines, t, minGap) {
  if (lines.length === 0)
    return {
      "show": false,
      "progress": 0
    };
  const i = lineIndexAt(lines, t);
  const from = i < 0 ? 0 : lines[i].end;
  const to = i + 1 < lines.length ? lines[i + 1].start : NaN;
  if (isNaN(to) || to - from < minGap || t < from)
    return {
      "show": false,
      "progress": 0
    };
  return {
    "show": true,
    "progress": clamp01((t - from) / (to - from))
  };
}

// "SOMETHING AIN'T RIGHT - XG"
function trackTag(title, artist) {
  const t = cleanTitle(title);
  const a = String(artist || "").trim();
  return (a ? t + " - " + a : t).toUpperCase();
}

// "Something Ain't Right · XG"
function trackLine(title, artist) {
  const t = cleanTitle(title);
  const a = String(artist || "").trim();
  return a ? t + " · " + a : t;
}

// An MPRIS Position read with busctl ("x 97702000", microseconds) in seconds, or -1
function busctlPosition(text) {
  const m = /^x\s+(-?\d+)\s*$/.exec(String(text || "").trim());
  return m ? Math.max(0, Number(m[1]) / 1e6) : -1;
}
