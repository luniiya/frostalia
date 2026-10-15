.pragma library

function progress(value, maximum) {
  if (!isFinite(value) || !isFinite(maximum) || maximum <= 0)
    return 0;
  return Math.max(0, Math.min(1, value / maximum));
}

// A short fill remains a rounded capsule; clipping reveals it gradually at zero.
function track(length, thickness, value, maximum) {
  const extent = Math.max(0, length);
  const cross = Math.max(0, thickness);
  const fraction = progress(value, maximum);
  return {
    fraction: fraction,
    filled: extent * fraction,
    capsule: Math.max(cross, extent * fraction),
    marker: Math.max(0, Math.min(extent - 2, extent * fraction - 1))
  };
}

function dimensions(vertical, lockKey, scale) {
  const ratio = Math.max(0.25, isFinite(scale) ? scale : 1);
  return {
    width: Math.round((lockKey ? 224 : vertical ? 104 : 352) * ratio),
    height: Math.round((lockKey ? 92 : vertical ? 296 : 112) * ratio)
  };
}
