.pragma library

// Screen corners are a host setting under General, independent of the UI style.
var baseRadius = 20;

function radius(ratio) {
  if (!isFinite(ratio))
    return baseRadius;
  return Math.round(baseRadius * Math.max(0, ratio));
}
