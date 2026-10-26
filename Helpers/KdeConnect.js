.pragma library

// Pure helpers for the KDE Connect integration. The service feeds them the
// JSON emitted by Tools/kdeconnect (see its README); QML only formats output.

// Paired devices, reachable ones first (the helper already sorts this way).
function pairedDevices(devices) {
  return (devices || []).filter(d => d && d.paired);
}

// The one device the UI shows: the remembered one while it is reachable,
// otherwise the first reachable paired device, otherwise the remembered or
// first paired device so the panel can still say it is offline.
function activeDevice(devices, preferredId) {
  const paired = pairedDevices(devices);
  const preferred = paired.find(d => d.id === preferredId) || null;
  if (preferred && preferred.reachable)
    return preferred;
  return paired.find(d => d.reachable) || preferred || paired[0] || null;
}

function isOnline(device) {
  return !!device && device.paired && device.reachable;
}

function hasPlugin(device, plugin) {
  return !!device && (device.plugins || []).indexOf("kdeconnect_" + plugin) >= 0;
}

function deviceIcon(device) {
  const kind = device ? device.type : "";
  if (kind === "tablet")
    return "device-tablet";
  if (kind === "desktop")
    return "device-desktop";
  if (kind === "laptop")
    return "device-laptop";
  if (kind === "tv")
    return "device-tv";
  if (!isOnline(device))
    return "device-mobile-off";
  return device.battery && device.battery.charging ? "device-mobile-charging" : "device-mobile";
}

function batteryText(device) {
  if (!isOnline(device) || !device.battery || device.battery.charge < 0)
    return "";
  return device.battery.charge + "%";
}

// What the liquid battery shows for a device. Stale batteries of offline phones are ignored.
function liquidState(device, warningThreshold) {
  const known = isOnline(device) && !!device.battery && device.battery.charge >= 0;
  const charging = known && !!device.battery.charging;
  const percent = known ? device.battery.charge : 0;
  return {
    "ready": known,
    "percent": percent,
    "charging": charging,
    "low": known && !charging && percent <= warningThreshold
  };
}

// KDE Connect reports 0-4 bars, or -1 when unknown.
function signalIcon(network) {
  if (!network || network.strength < 0)
    return "antenna-bars-off";
  return "antenna-bars-" + (Math.min(4, network.strength) + 1);
}

// Feature pages offered for a device, in display order.
var features = [
  { id: "messages", plugin: "sms", icon: "messages" },
  { id: "notifications", plugin: "notifications", icon: "bell" },
  { id: "media", plugin: "mprisremote", icon: "player-play" },
  { id: "remote", plugin: "remotecontrol", icon: "pointer" },
  { id: "files", plugin: "sftp", icon: "folder" }
];

// One-tap actions shown on the home page.
var actions = [
  { id: "ring", plugin: "findmyphone", icon: "bell-ringing" },
  { id: "ping", plugin: "ping", icon: "device-mobile-vibration" },
  { id: "clipboard", plugin: "clipboard", icon: "clipboard" },
  { id: "share", plugin: "share", icon: "file-upload" }
];

function availableFeatures(device) {
  if (!isOnline(device))
    return [];
  return features.filter(f => hasPlugin(device, f.plugin) || (f.id === "remote" && hasPlugin(device, "remotekeyboard")));
}

function availableActions(device) {
  if (!isOnline(device))
    return [];
  return actions.filter(a => hasPlugin(device, a.plugin));
}

// Plugins the device settings page can toggle: everything both sides support.
function pluginEntries(device) {
  if (!device)
    return [];
  const loaded = device.plugins || [];
  return (device.supportedPlugins || []).slice().sort().map(id => ({
                                                                     id: id,
                                                                     name: pluginName(id),
                                                                     enabled: loaded.indexOf(id) >= 0
                                                                   }));
}

function pluginName(id) {
  const name = String(id).replace(/^kdeconnect_/, "").replace(/_/g, " ");
  return name.charAt(0).toUpperCase() + name.slice(1);
}

// ---------------------------------------------------------------------------
// Contacts and SMS

// Compare numbers by their last nine digits so "+33 6 12 34 56 78" and
// "06 12 34 56 78" match.
function normalizeNumber(number) {
  const digits = String(number || "").replace(/\D/g, "");
  return digits.length > 9 ? digits.slice(-9) : digits;
}

function contactFor(number, contacts) {
  const key = normalizeNumber(number);
  if (!key)
    return null;
  return (contacts || []).find(c => (c.numbers || []).some(n => normalizeNumber(n) === key)) || null;
}

function displayName(number, contacts) {
  const contact = contactFor(number, contacts);
  return contact ? contact.name : String(number || "");
}

function threadTitle(addresses, contacts) {
  return (addresses || []).map(a => displayName(a, contacts)).join(", ");
}

// Avatar letters for a contact; "#" for a bare phone number.
function initials(name) {
  const text = String(name || "").trim();
  if (!text)
    return "";
  if (/^\+?[\d\s().-]+$/.test(text))
    return "#";
  // Words starting with a letter or digit (punctuation is ignored).
  const words = text.split(/\s+/).filter(w => w.toLowerCase() !== w.toUpperCase() || /^\d/.test(w));
  if (!words.length)
    return "";
  const first = Array.from(words[0])[0];
  const last = words.length > 1 ? Array.from(words[words.length - 1])[0] : "";
  return (first + last).toUpperCase();
}

// Thread list: newest message per thread, newest thread first.
function sortThreads(latest) {
  return (latest || []).slice().sort((a, b) => b.date - a.date);
}

// Applies a message event to the thread list.
function upsertThread(threads, message) {
  const next = (threads || []).filter(t => t.thread !== message.thread);
  const current = (threads || []).find(t => t.thread === message.thread);
  next.push(current && current.date > message.date ? current : message);
  return sortThreads(next);
}

function removeThread(threads, thread) {
  return (threads || []).filter(t => t.thread !== thread);
}

function unreadCount(threads) {
  return (threads || []).filter(t => !t.sent && !t.read).length;
}

// Applies a message event to an open thread, oldest first. A sent message
// replaces the optimistic "pending" bubble with the same text.
function mergeMessage(messages, message) {
  let next = (messages || []).filter(m => m.uid !== message.uid);
  if (message.sent) {
    const pending = next.findIndex(m => m.pending && m.body === message.body);
    if (pending >= 0)
      next.splice(pending, 1);
  }
  next.push(message);
  next.sort((a, b) => a.date - b.date || a.uid - b.uid);
  return next;
}

function pendingMessage(thread, text, now, serial) {
  return {
    body: text,
    addresses: [],
    date: now,
    sent: true,
    read: true,
    thread: thread,
    uid: -1 - serial,
    attachments: [],
    pending: true
  };
}

var groupGapMs = 5 * 60 * 1000;

function sameDay(a, b) {
  const x = new Date(a), y = new Date(b);
  return x.getFullYear() === y.getFullYear() && x.getMonth() === y.getMonth() && x.getDate() === y.getDate();
}

// Bubble layout for a thread: consecutive messages in the same direction
// within five minutes form a group; a new day starts a new group.
function bubbles(messages) {
  const list = messages || [];
  return list.map((m, i) => {
                    const prev = list[i - 1];
                    const next = list[i + 1];
                    const joinsPrev = !!prev && prev.sent === m.sent && m.date - prev.date < groupGapMs && sameDay(prev.date, m.date);
                    const joinsNext = !!next && next.sent === m.sent && next.date - m.date < groupGapMs && sameDay(m.date, next.date);
                    return {
                      message: m,
                      first: !joinsPrev,
                      last: !joinsNext,
                      daySeparator: !prev || !sameDay(prev.date, m.date)
                    };
                  });
}

// How to print a message timestamp: "time" today, "weekday" within the last
// week, "date" before that.
function timeKind(date, now) {
  if (sameDay(date, now))
    return "time";
  const startOfToday = new Date(now);
  startOfToday.setHours(0, 0, 0, 0);
  return startOfToday.getTime() - date < 6 * 24 * 3600 * 1000 ? "weekday" : "date";
}

function attachmentImages(message) {
  return ((message && message.attachments) || []).filter(a => a.thumbnail && /^image\//.test(a.mime));
}

// ---------------------------------------------------------------------------
// Media

function formatDuration(ms) {
  const total = Math.max(0, Math.floor((ms || 0) / 1000));
  const h = Math.floor(total / 3600);
  const m = Math.floor(total % 3600 / 60);
  const s = String(total % 60).padStart(2, "0");
  return h > 0 ? h + ":" + String(m).padStart(2, "0") + ":" + s : m + ":" + s;
}

function progress(media) {
  if (!media || !(media.length > 0))
    return 0;
  return Math.max(0, Math.min(1, media.position / media.length));
}

// ---------------------------------------------------------------------------
// Remote input

// Scales touchpad motion and carries the fractional part to the next event,
// so slow drags still move the remote cursor.
function touchpadStep(carry, dx, dy, sensitivity) {
  const x = (carry ? carry.x : 0) + dx * sensitivity;
  const y = (carry ? carry.y : 0) + dy * sensitivity;
  const mx = Math.trunc(x), my = Math.trunc(y);
  return {
    dx: mx,
    dy: my,
    carry: {
      x: x - mx,
      y: y - my
    }
  };
}

// Qt key codes to KDE Connect remote keyboard special keys.
var specialKeys = {
  0x01000003: 1, // Backspace
  0x01000001: 2, // Tab
  0x01000012: 4, // Left
  0x01000013: 5, // Up
  0x01000014: 6, // Right
  0x01000015: 7, // Down
  0x01000016: 8, // PageUp
  0x01000017: 9, // PageDown
  0x01000010: 10, // Home
  0x01000011: 11, // End
  0x01000004: 12, // Return
  0x01000005: 12, // Enter
  0x01000007: 13, // Delete
  0x01000000: 14 // Escape
};

// Returns the keyPress command fields for a Qt key event, or null.
function keyPress(key, text, modifiers) {
  const shift = (modifiers & 0x02000000) !== 0;
  const ctrl = (modifiers & 0x04000000) !== 0;
  const alt = (modifiers & 0x08000000) !== 0;
  let special = specialKeys[key] || 0;
  if (!special && key >= 0x01000030 && key <= 0x0100003b)
    special = 21 + key - 0x01000030; // F1-F12
  if (special)
    return {
      key: "",
      special: special,
      shift: shift,
      ctrl: ctrl,
      alt: alt
    };
  let chars = String(text || "");
  if ((ctrl || alt) && key >= 0x20 && key < 0x7f)
    chars = String.fromCharCode(key).toLowerCase();
  if (!chars || chars.charCodeAt(0) < 0x20)
    return null;
  return {
    key: chars,
    special: 0,
    shift: shift,
    ctrl: ctrl,
    alt: alt
  };
}

// ---------------------------------------------------------------------------
// Share

// Dropped or picked paths as URLs the share plugin accepts.
function shareUrls(paths) {
  return (paths || []).map(p => String(p)).filter(p => p !== "").map(p => /^[a-z][a-z0-9+.-]*:/i.test(p) ? p : "file://" + encodeURI(p));
}

// Run commands editor: drop blank rows before saving.
function cleanCommands(commands) {
  return (commands || []).map(c => ({
                                      id: c.id || "",
                                      name: String(c.name || "").trim(),
                                      command: String(c.command || "").trim()
                                    })).filter(c => c.name !== "" && c.command !== "");
}

// ---------------------------------------------------------------------------
// Panel navigation

// Pages that still work while the phone is offline.
var offlinePages = ["home", "device"];

function pushPage(stack, page, props) {
  return (stack || []).concat([{
                                 page: page,
                                 props: props || {}
                               }]);
}

function popPage(stack) {
  return stack && stack.length > 1 ? stack.slice(0, -1) : [{
                                                            page: "home",
                                                            props: {}
                                                          }];
}

// Drops pages that need a connected phone once it goes offline.
function reachablePages(stack, online) {
  if (online)
    return stack;
  const kept = (stack || []).filter(p => offlinePages.indexOf(p.page) >= 0);
  return kept.length ? kept : [{
                                page: "home",
                                props: {}
                              }];
}

// ---------------------------------------------------------------------------
// Bar and control center

// "77% · Charging · LTE" status line; labels holds the translated words
// (offline, charging, connected).
function statusLine(device, labels) {
  if (!device)
    return "";
  if (!isOnline(device))
    return labels.offline;
  const parts = [];
  if (device.battery && device.battery.charge >= 0)
    parts.push(device.battery.charge + "%" + (device.battery.charging ? " · " + labels.charging : ""));
  if (device.network && device.network.type && device.network.type !== "Unknown")
    parts.push(device.network.type);
  return parts.join(" · ") || labels.connected;
}

// Unread SMS count after the battery text; off unless the user enables it.
function unreadSuffix(unread, showUnread) {
  return showUnread && unread > 0 ? " · " + unread : "";
}

// The bar widget stays out of the way until a phone is connected, unless the
// user wants it always visible (it then shows the offline icon).
function widgetVisible(enabled, device, hideWhenOffline) {
  if (!enabled)
    return false;
  return isOnline(device) || !hideWhenOffline;
}
