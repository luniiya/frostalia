.pragma library

function snappedScale(value, minimum, maximum, precise, baseWidth, gridSize) {
  if (!isFinite(value))
    value = 1;
  let scale = Math.max(minimum, Math.min(maximum, value));
  if (!precise) {
    if (baseWidth > 0 && gridSize > 0)
      scale = Math.max(gridSize, Math.round(baseWidth * scale / gridSize) * gridSize) / baseWidth;
    else
      scale = Math.round(scale * 10) / 10;
  }
  return Math.max(minimum, Math.min(maximum, scale));
}

function scaleText(scale) {
  return scale.toFixed(2);
}

// Keep the opposite edge fixed while resizing one axis.
function resizedAxis(start, length, delta, leading, minimum, maximum, step, precise) {
  if (delta === 0)
    return { start: start, length: length };
  let next = length + (leading ? -delta : delta);
  if (!precise && step > 0)
    next = Math.round(next / step) * step;
  next = Math.max(minimum, Math.min(maximum, next));
  return { start: leading ? start + length - next : start, length: next };
}

function feedbackPosition(x, y, width, height, labelWidth, labelHeight, screenWidth, screenHeight, gap) {
  const left = Math.max(gap, Math.min(x + (width - labelWidth) / 2, screenWidth - labelWidth - gap));
  const preferredTop = y - labelHeight - gap >= gap ? y - labelHeight - gap : y + height + gap;
  const top = Math.max(gap, Math.min(preferredTop, screenHeight - labelHeight - gap));
  return { x: left - x, y: top - y };
}
