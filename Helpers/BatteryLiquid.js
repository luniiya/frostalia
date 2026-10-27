.pragma library

// Geometry and state decisions for the liquid battery bar widget.
// The liquid is a wide sine polygon that slides sideways inside a clipped container.

// From this charge up the container reads as full
var fullThreshold = 95;

function fillFraction(percent, ready) {
  if (!ready || !isFinite(percent))
    return 0;
  if (percent >= fullThreshold)
    return 1;
  return Math.max(0, Math.min(1, percent / 100));
}

// Theme color role of the liquid
function liquidColorRole(ready, low, critical) {
  return ready && (low || critical) ? "error" : "primary";
}

// Scales with the narrow side of the container, so a taller container doesn't get taller waves
function waveAmplitude(containerWidth, containerHeight) {
  return Math.max(1.2, Math.min(containerWidth, containerHeight) * 0.055);
}

// Distance from the top of the wave item to its resting surface line.
function surfaceOffset(amplitude) {
  return amplitude;
}

// Total wave item height: crest and trough room plus the liquid body below the surface.
function waveItemHeight(containerHeight, amplitude) {
  return containerHeight + 3 * amplitude;
}

// y of the wave item inside the container. The surface line sits at the top of the
// liquid; 0% parks the wave fully below the container, 100% fully covers it.
function waveItemY(fraction, containerHeight, amplitude) {
  var surface = (containerHeight + 2 * amplitude) * (1 - fraction) - amplitude;
  return surface - surfaceOffset(amplitude);
}

// Closed polygon: a sine surface over `periods` wavelengths, then down and back along the bottom.
// One wavelength is a seamless loop, so sliding the item by `wavelength` repeats the picture.
function wavePolygon(wavelength, periods, amplitude, itemHeight, phase, stepsPerPeriod) {
  var steps = Math.max(4, stepsPerPeriod || 16);
  var total = steps * periods;
  var points = [];
  for (var i = 0; i <= total; i++) {
    var x = wavelength * periods * i / total;
    var y = surfaceOffset(amplitude) + amplitude * Math.sin(2 * Math.PI * x / wavelength + (phase || 0));
    points.push({
                  "x": x,
                  "y": y
                });
  }
  points.push({
                "x": wavelength * periods,
                "y": itemHeight
              });
  points.push({
                "x": 0,
                "y": itemHeight
              });
  return points;
}

// Charging bubbles: each one rises from the bottom of the container all the way to its top,
// with its own size, speed and sideways wobble, then rests for a random while. They are
// sized by the container, not the liquid, so they still show when the charge is low.
// `rand` is Math.random, injectable for tests.
function bubbleSpec(rand, width, containerHeight) {
  var size = Math.max(1.5, containerHeight * (0.09 + rand() * 0.08));
  var margin = size / 2 + 2;
  return {
    "size": size,
    "x": margin + rand() * Math.max(0, width - 2 * margin),
    "wobble": rand() * Math.min(2.5, width * 0.1),
    "cycles": 0.5 + rand() * 1.5,
    "duration": 2800 + rand() * 2400,
    "rest": 1500 + rand() * 4500
  };
}

// Center of a bubble at progress 0..1 of its rise: from just below the container to just above it.
function bubblePosition(spec, progress, containerHeight) {
  var start = containerHeight + spec.size / 2;
  var end = -spec.size / 2;
  return {
    "x": spec.x + spec.wobble * Math.sin(progress * 2 * Math.PI * spec.cycles),
    "y": start + (end - start) * progress
  };
}

// Fades in after the start of the rise and out before the surface, peaking at maxOpacity.
function bubbleOpacity(progress, maxOpacity) {
  return Math.max(0, Math.min(1, progress * 6, (1 - progress) * 4)) * maxOpacity;
}

// How far a bubble centered at `y` has left the liquid whose surface line is at `surfaceY`:
// 0 inside it, 1 above it, blended across the wave's `amplitude` either side of the line.
// Above the liquid a bubble takes the liquid's color, so it shows on the empty part.
function bubbleAbove(y, surfaceY, amplitude) {
  var band = Math.max(1, amplitude);
  return Math.max(0, Math.min(1, (surfaceY + band - y) / (2 * band)));
}

// Peak opacity of a bubble: faint white inside the liquid, stronger above it
function bubblePeakOpacity(above) {
  var inside = 0.4;
  var outside = 0.85;
  return inside + (outside - inside) * above;
}

// Container size along the bar axis. The battery uses a tall container, other widgets pass 1 for a round one.
function containerLength(capsuleThickness, lengthFactor) {
  return Math.round(capsuleThickness * (lengthFactor || 3.2));
}

// Lists parsed from the settings file are array-likes, not always real arrays.
function isList(value) {
  return !!value && typeof value === "object" && typeof value.length === "number";
}

// The liquid mode replaces the old always-visible icon pill.
function migrateDisplayMode(sections) {
  if (!sections)
    return null;
  var changed = false;
  var result = {};
  for (var key in sections) {
    var list = sections[key];
    if (!isList(list)) {
      result[key] = list;
      continue;
    }
    result[key] = Array.prototype.map.call(list, function (w) {
      if (w && w.id === "Battery" && w.displayMode === "icon-always") {
        changed = true;
        return Object.assign({}, w, {
                               "displayMode": "liquid"
                             });
      }
      return w;
    });
  }
  return changed ? result : null;
}
