.pragma library

// Match the padding along the workspace row to the gap around each dot.
function capsulePadding(capsuleSize, pillSize) {
  return Math.max(0, (capsuleSize - pillSize) / 2);
}
