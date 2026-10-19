.pragma library

// Five-cell rows mix compact toggles with labeled Bluetooth/power/phone tiles.
var columns = 5;
function shortcutRows(left, right) {
  const rows = [];
  let row = [];
  let used = 0;
  const shortcuts = (left || []).concat(right || []);
  for (let index = 0; index < shortcuts.length; index++) {
    const settings = shortcuts[index];
    if (!settings || !settings.id)
      continue;
    const span = ["Bluetooth", "PowerProfile", "KdeConnect"].includes(settings.id) ? 2 : 1;
    if (used + span > columns) {
      rows.push(row);
      row = [];
      used = 0;
    }
    row.push({ settings: settings, span: span, index: index });
    used += span;
  }
  if (row.length)
    rows.push(row);
  return rows;
}

function cellWidth(width, gap, span) {
  return Math.max(0, (width - (columns - 1) * gap) / columns * span + (span - 1) * gap);
}

// Equal share of a row for count items separated by gap.
function equalWidth(width, gap, count) {
  if (!(count > 0))
    return 0;
  return Math.max(0, (width - (count - 1) * gap) / count);
}

// Card height with the same padding above and below its content.
function paddedHeight(contentHeight, padding) {
  return Math.max(0, contentHeight) + 2 * Math.max(0, padding);
}

function cardEnabled(cards, id) {
  return (cards || []).some(card => card.id === id && card.enabled);
}

function invoke(action, button) {
  if (!action || action.enabled === false)
    return false;
  const name = button === "right" ? "rightClicked" : button === "middle" ? "middleClicked" : "clicked";
  if (typeof action[name] !== "function")
    return false;
  action[name]();
  return true;
}

function progress(position, length) {
  if (!Number.isFinite(position) || !Number.isFinite(length) || length <= 0)
    return 0;
  return Math.max(0, Math.min(1, position / length));
}


function notificationHeight(count, scale) {
  return Math.round((count > 0 ? Math.min(300, Math.max(180, count * 108 + 52)) : 132) * scale);
}

// Keep enabled cards in saved order; unavailable cards must not reserve space.
function visibleCards(cards, weatherEnabled, hasShortcuts) {
  const supported = ["profile-card", "shortcuts-card", "audio-card", "brightness-card",
                     "weather-card", "media-sysmon-card", "notification-card", "calendar-month-card"];
  return (cards || []).filter(card => card && card.enabled && supported.includes(card.id)
    && (card.id !== "weather-card" || weatherEnabled)
    && (card.id !== "shortcuts-card" || hasShortcuts));
}

function withAdditionalCards(cards) {
  const result = (cards || []).slice();
  for (const id of ["notification-card", "calendar-month-card"]) {
    if (!result.some(card => card && card.id === id))
      result.push({ id: id, enabled: true });
  }
  return result;
}
