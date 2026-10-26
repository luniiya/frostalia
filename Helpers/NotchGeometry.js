.pragma library

// Pure geometry for the "notch" bar type. Kept free of QML/Quickshell
// dependencies so it can be unit tested (see Tests/tst_notchgeometry.qml).
//
// Corner states follow ShapeCornerHelper:
//   -1 flat, 0 rounded, 1 outer curve on X, 2 outer curve on Y

// The bar always keeps at least this fraction of its screen edge
var minBarFraction = 0.2;

// Empty gap left at each end of the bar, clamped so the bar never vanishes
function inset(edgeLength, gap) {
  if (!(edgeLength > 0))
    return 0;
  var g = Math.max(0, Number(gap) || 0);
  return Math.floor(Math.min(g, edgeLength * (1 - minBarFraction) / 2));
}

function isVertical(position) {
  return position === "left" || position === "right";
}

// True when the corner lies on the screen edge the bar is attached to
function cornerOnScreenEdge(corner, position) {
  switch (corner) {
  case "topLeft":
    return position === "top" || position === "left";
  case "topRight":
    return position === "top" || position === "right";
  case "bottomLeft":
    return position === "bottom" || position === "left";
  case "bottomRight":
    return position === "bottom" || position === "right";
  }
  return false;
}

// Which end of the bar ("start" = top/left, "end" = bottom/right) a corner belongs to
function cornerEnd(corner, position) {
  if (isVertical(position))
    return corner.indexOf("top") === 0 ? "start" : "end";
  return corner.indexOf("Left") !== -1 ? "start" : "end";
}

// Corners on the screen edge flare outward along it, the others are rounded
function cornerState(corner, position, outerCorners) {
  if (!cornerOnScreenEdge(corner, position))
    return 0;
  if (outerCorners)
    return isVertical(position) ? 2 : 1;
  return -1;
}

// Insets for both ends once an attached panel is taken into account: an end the
// panel reaches past is filled so the panel meets the screen edge like on a simple
// bar. panelStart/panelEnd are along the bar axis.
function fillInsets(notchInset, edgeLength, hasPanel, panelStart, panelEnd) {
  return {
    "start": (hasPanel && panelStart < notchInset) ? 0 : notchInset,
    "end": (hasPanel && panelEnd > edgeLength - notchInset) ? 0 : notchInset
  };
}

// Position (along the bar axis) for a panel attached to a notch bar. A panel that stops
// within two corner radii of a bar end, without reaching past it, would leave a sliver of
// bar beside it: the bar's rounded end and the panel's own flared corner make two notches
// in a row. It snaps to the screen edge instead, which fills that end (see fillInsets), so
// there is a single notch. Panels that reach past an end already are kept.
function snapToBarEnds(start, size, notchInset, edgeLength, radius) {
  var r = radius || 0;
  if (r <= 0 || !(size > 0) || size >= edgeLength)
    return start;
  var reach = 2 * r;
  var end = start + size;
  if (start >= notchInset && start < notchInset + reach)
    return 0;
  if (end <= edgeLength - notchInset && end > edgeLength - notchInset - reach)
    return edgeLength - size;
  return start;
}
