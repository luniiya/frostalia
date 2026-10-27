.pragma library

// Keep the rendered grid and keyboard navigation on the same column count.
function geometry(count, mode, viewportWidth, scale) {
  const gap = 12 * scale;
  const padding = 24 * scale;
  const available = Math.max(1, viewportWidth - 48 * scale - padding * 2);
  const fitting = Math.max(1, Math.floor((available + gap) / (148 * scale + gap)));
  const desired = mode === "single-row" ? count : Math.min(3, Math.ceil(Math.sqrt(count)));
  const columns = Math.max(1, Math.min(Math.max(1, desired), fitting));
  const tileWidth = Math.min(148 * scale, available);
  return {
    columns: columns,
    rows: Math.ceil(count / columns),
    tileWidth: tileWidth,
    tileHeight: 124 * scale,
    gap: gap,
    padding: padding,
    width: columns * tileWidth + (columns - 1) * gap + padding * 2
  };
}

function navigate(count, columns, selected, direction) {
  if (count <= 0)
    return -1;
  if (selected < 0 || selected >= count)
    return direction === "left" || direction === "up" ? count - 1 : 0;
  const rows = Math.ceil(count / columns);
  let row = Math.floor(selected / columns);
  let col = selected % columns;
  if (direction === "left" || direction === "right") {
    const items = Math.min(columns, count - row * columns);
    col = (col + (direction === "left" ? -1 : 1) + items) % items;
  } else {
    row = (row + (direction === "up" ? -1 : 1) + rows) % rows;
    col = Math.min(col, Math.min(columns, count - row * columns) - 1);
  }
  return row * columns + col;
}

// How a tile of the large menu looks: `active` while selected (keyboard or hover)
// or counting down, `pending` while its countdown runs, `danger` for shutdown.
function tileState(index, selectedIndex, action, pendingAction, timerActive, isShutdown) {
  const pending = !!timerActive && !!action && action === pendingAction;
  return {
    "active": pending || (index >= 0 && index === selectedIndex),
    "pending": pending,
    "danger": !!isShutdown
  };
}

// Elapsed share of the countdown, 0 at the start and 1 when the action runs.
function countdownProgress(remaining, duration) {
  if (!(duration > 0))
    return 0;
  return Math.max(0, Math.min(1, 1 - remaining / duration));
}

// Scroll offset that keeps the selected row of the tile grid in view.
function revealY(selected, columns, tileHeight, gap, contentY, viewportHeight) {
  if (selected < 0 || columns < 1)
    return contentY;
  const top = Math.floor(selected / columns) * (tileHeight + gap);
  return Math.max(0, Math.min(top, Math.max(contentY, top + tileHeight - viewportHeight)));
}
