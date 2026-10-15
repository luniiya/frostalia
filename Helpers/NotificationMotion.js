.pragma library

function inputOrigin(x, y, width, height, insetX, insetY, scale, offsetX, offsetY) {
  return {x: x + width / 2 + (insetX - width / 2) * scale + offsetX,
          y: y + height / 2 + (insetY - height / 2) * scale + offsetY};
}

function shouldResumeTimeout(hovered, pressed) {
  return !hovered && !pressed;
}

// Keep the card inside its layer surface while retaining a rubber-band feel.
function dragOffset(distance, limit) {
  if (!isFinite(distance) || !isFinite(limit) || limit <= 0)
    return 0;
  return limit * distance / (limit + Math.abs(distance));
}

function sampleVelocity(previous, delta, elapsedMs) {
  if (!isFinite(delta) || !isFinite(elapsedMs) || elapsedMs <= 0 || elapsedMs > 120)
    return 0;
  var instant = Math.max(-2400, Math.min(2400, delta * 1000 / elapsedMs));
  return previous * 0.35 + instant * 0.65;
}

function shouldDismiss(x, y, vx, vy, width, height) {
  var horizontalDistance = Math.max(100, width * 0.28);
  var verticalDistance = Math.max(80, height * 0.55);
  // A flick must travel far enough and point away from the origin. Reversing
  // direction immediately before release lets the user rescue a short throw.
  return Math.abs(x) >= horizontalDistance || Math.abs(y) >= verticalDistance
      || (Math.abs(x) >= 18 && Math.abs(vx) >= 800 && x * vx > 0)
      || (Math.abs(y) >= 18 && Math.abs(vy) >= 800 && y * vy > 0);
}

function springStep(position, velocity, elapsedMs, limit, animationDisabled, bounds) {
  if (animationDisabled || !isFinite(position) || !isFinite(velocity))
    return {position: 0, velocity: 0, settled: true};
  // Small integration steps remain stable even after a delayed rendering frame.
  var remaining = Math.max(0, Math.min(64, elapsedMs)) / 1000;
  while (remaining > 0) {
    var dt = Math.min(1 / 240, remaining);
    velocity += (-240 * position - 22 * velocity) * dt;
    position += velocity * dt;
    remaining -= dt;
  }
  var lower = bounds ? -bounds.negative : -limit;
  var upper = bounds ? bounds.positive : limit;
  if (position < lower || position > upper) {
    position = Math.max(lower, Math.min(upper, position));
    velocity *= -0.25;
  }
  var settled = Math.abs(position) < 0.1 && Math.abs(velocity) < 0.5;
  return {position: settled ? 0 : position, velocity: settled ? 0 : velocity, settled: settled};
}
