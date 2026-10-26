.pragma library

// Where things are on screen, for scripts that click the running shell
// (Scripts/dev/ui-screenshots.sh asks `qs -c frostalia ipc call state widgetRect <id> <screen>`).

// Top-left of a layer-shell window in its screen. `anchors` and `margins` are the window's
// {top, bottom, left, right}; an edge that is not anchored on either side is centered.
function windowOrigin(anchors, margins, width, height, screenWidth, screenHeight) {
  function axis(start, end, startMargin, endMargin, size, screenSize) {
    if (start)
      return startMargin;
    if (end)
      return screenSize - endMargin - size;
    return Math.round((screenSize - size) / 2);
  }
  return {
    "x": axis(anchors.left, anchors.right, margins.left || 0, margins.right || 0, width, screenWidth),
    "y": axis(anchors.top, anchors.bottom, margins.top || 0, margins.bottom || 0, height, screenHeight)
  };
}

// "x y width height" in global layout coordinates, as `hyprctl cursorpos` uses them
function globalRect(screen, origin, local, width, height) {
  return [Math.round(screen.x + origin.x + local.x), Math.round(screen.y + origin.y + local.y), Math.round(width), Math.round(height)].join(" ");
}
