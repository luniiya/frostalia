.pragma library

// Compact end-4 style media popup: art on the left, metadata and controls on the right.

function timeLabel(hasPlayer, position, length) {
  if (!hasPlayer || !length)
    return "";
  return (position || "0:00") + " / " + length;
}

// Material expressive play button: rounded square while playing, circle while paused.
function playButtonRadius(size, playing) {
  size = Number.isFinite(size) ? Math.max(0, size) : 0;
  return playing ? Math.round(size * 0.3) : size / 2;
}

// Art fills the card height minus padding but never squeezes the text column below minText.
function artSize(cardWidth, cardHeight, padding, minText) {
  const byHeight = Math.max(0, cardHeight - 2 * padding);
  const byWidth = Math.max(0, cardWidth - 3 * padding - (minText || 0));
  return Math.floor(Math.min(byHeight, byWidth));
}

// Background spectrum follows the global audio visualizer type rather than the bar pill's toggle.
function backgroundVisualizer(type) {
  if (!type || type === "none")
    return "";
  return type === "linear" ? "bars" : "wave";
}
