.pragma library

function fraction(value) {
  return Number.isFinite(value) ? Math.max(0, Math.min(1, value)) : 0;
}

// Taper the wave at both ends so it meets the thumb without a jump.
function points(width, height, progress, amplitude, wavelength, phase) {
  width = Number.isFinite(width) ? Math.max(0, width) : 0;
  height = Number.isFinite(height) ? Math.max(0, height) : 0;
  const end = width * fraction(progress);
  const center = height / 2;
  amplitude = Number.isFinite(amplitude) ? Math.max(0, Math.min(center, amplitude)) : 0;
  wavelength = Number.isFinite(wavelength) ? Math.max(4, wavelength) : 20;
  phase = Number.isFinite(phase) ? phase : 0;
  if (end === 0)
    return [];
  if (amplitude === 0)
    return [{x: 0, y: center}, {x: end, y: center}];
  const steps = Math.max(1, Math.ceil(end / 2));
  const result = [];
  for (let i = 0; i <= steps; ++i) {
    const x = end * i / steps;
    const taper = Math.min(wavelength / 3, end / 2);
    const envelope = taper > 0 ? Math.min(1, x / taper, (end - x) / taper) : 0;
    result.push({x: x, y: center + amplitude * envelope * Math.sin(x * 2 * Math.PI / wavelength - phase)});
  }
  return result;
}

function path(points) {
  return points.map((point, index) => (index ? "L " : "M ") + point.x + " " + point.y).join(" ");
}
