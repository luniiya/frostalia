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

// Grid cell size for a screen. Lines pass through the screen center on both axes when a size allows it.
function gridSize(screenWidth, screenHeight) {
  if (!screenWidth || !screenHeight)
    return 30;
  const baseSize = Math.max(20, Math.min(60, Math.round(screenWidth * 0.015)));
  const centerX = screenWidth / 2;
  const centerY = screenHeight / 2;
  let bestSize = baseSize;
  let bestDistance = Infinity;
  for (let offset = -10; offset <= 10; offset++) {
    const candidate = baseSize + offset;
    if (candidate < 20 || candidate > 60)
      continue;
    const remainderX = centerX % candidate;
    const remainderY = centerY % candidate;
    if (remainderX === 0 && remainderY === 0)
      return candidate;
    const distance = Math.abs(remainderX) + Math.abs(remainderY);
    if (distance < bestDistance) {
      bestDistance = distance;
      bestSize = candidate;
    }
  }
  const gcd = (a, b) => {
    while (b !== 0) {
      const temp = b;
      b = a % b;
      a = temp;
    }
    return a;
  };
  const centerGcd = gcd(Math.round(centerX), Math.round(centerY));
  if (centerGcd > 0) {
    for (let divisor = Math.floor(centerGcd / 60); divisor <= Math.ceil(centerGcd / 20); divisor++) {
      if (divisor === 0 || centerGcd % divisor !== 0)
        continue;
      const candidate = centerGcd / divisor;
      if (candidate >= 20 && candidate <= 60 && Math.abs(candidate - baseSize) < Math.abs(bestSize - baseSize))
        bestSize = candidate;
    }
  }
  return bestSize;
}

// Outer length of a widget on the grid: whole cells, never smaller than its content.
function gridLength(length, grid) {
  if (!(grid > 0) || !(length > 0))
    return length;
  return Math.max(1, Math.ceil(length / grid - 1e-9)) * grid;
}
