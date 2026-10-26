.pragma library

// Pure geometry for the Edit Desktop screen: the desktop shrinks into a framed card, the card is
// drawn in screen coordinates, widgets keep their desktop coordinates inside it.
// Kept free of QML/Quickshell dependencies so it can be unit tested (Tests/tst_editdesktopgeometry.qml).

// Card: the biggest copy of the screen that fits inside `pad` on all sides and above the shelf.
// x/y is its top-left corner on screen, s the scale from desktop pixels to screen pixels.
function cardRect(screenWidth, screenHeight, pad, trayHeight) {
  var sw = Math.max(1, screenWidth);
  var sh = Math.max(1, screenHeight);
  var p = Math.max(0, pad || 0);
  var tray = Math.max(0, trayHeight || 0);
  var availW = Math.max(1, sw - 2 * p);
  var availH = Math.max(1, sh - 2 * p - tray);
  var s = Math.min(1, availW / sw, availH / sh);
  var w = sw * s;
  var h = sh * s;
  return {
    "x": (sw - w) / 2,
    "y": p + (availH - h) / 2,
    "s": s,
    "width": w,
    "height": h
  };
}

function clamp01(value) {
  return Math.max(0, Math.min(1, isFinite(value) ? value : 0));
}

// Transform of the whole desktop at progress 0 (the normal desktop) .. 1 (the card).
function stageTransform(progress, rect) {
  var p = clamp01(progress);
  return {
    "scale": 1 + (rect.s - 1) * p,
    "x": rect.x * p,
    "y": rect.y * p
  };
}

// A point on screen (pointer) as a desktop point, and whether it is on the card.
function toDesktop(px, py, rect, screenWidth, screenHeight) {
  var s = rect.s > 0 ? rect.s : 1;
  var x = (px - rect.x) / s;
  var y = (py - rect.y) / s;
  return {
    "x": x,
    "y": y,
    "inside": x >= 0 && y >= 0 && x <= screenWidth && y <= screenHeight
  };
}

// Where a widget dropped at a desktop point lands: centered on it, kept on the desktop.
function spotFor(widgetWidth, widgetHeight, pointX, pointY, screenWidth, screenHeight) {
  var x = pointX - widgetWidth / 2;
  var y = pointY - widgetHeight / 2;
  x = Math.max(0, Math.min(x, Math.max(0, screenWidth - widgetWidth)));
  y = Math.max(0, Math.min(y, Math.max(0, screenHeight - widgetHeight)));
  return {
    "x": Math.round(x),
    "y": Math.round(y)
  };
}

// Size of a widget under the pointer while it is pulled off the shelf: as big as it will be on the card.
function ghostSize(widgetWidth, widgetHeight, rect) {
  return {
    "width": widgetWidth * rect.s,
    "height": widgetHeight * rect.s
  };
}

// Pointer movement on a shelf tile: a pull up toward the card, a scroll of the shelf, or still a click.
// The shelf scrolls sideways and steals a press after about 10 px, so a pull is decided before that.
var pullDistance = 5;
var pullSlope = 0.6;
var clickSlop = 10;

function gesture(dx, dy) {
  var ax = Math.abs(dx);
  var ay = Math.abs(dy);
  if (dy <= -pullDistance && ay >= ax * pullSlope)
    return "pull";
  if (Math.max(ax, ay) >= clickSlop)
    return "scroll";
  return "click";
}

function _edges(r, horizontal) {
  var start = horizontal ? r.x : r.y;
  var size = horizontal ? r.width : r.height;
  return [start, start + size / 2, start + size];
}

// Snap a widget rectangle being dragged: first to the edges and centers of the other widgets,
// else to the grid. Returns the snapped position and the guide lines to draw.
//   rect, others[i]: {x, y, width, height}
function snap(rect, others, grid, threshold) {
  var thr = threshold > 0 ? threshold : 0;
  var result = {
    "x": rect.x,
    "y": rect.y,
    "guides": []
  };
  var axes = [true, false];
  for (var a = 0; a < axes.length; a++) {
    var horizontal = axes[a];
    var mine = _edges(rect, horizontal);
    var best = null;
    for (var i = 0; i < others.length; i++) {
      var theirs = _edges(others[i], horizontal);
      for (var m = 0; m < mine.length; m++) {
        for (var t = 0; t < theirs.length; t++) {
          var delta = theirs[t] - mine[m];
          if (Math.abs(delta) <= thr && (best === null || Math.abs(delta) < Math.abs(best.delta)))
            best = {
              "delta": delta,
              "line": theirs[t]
            };
        }
      }
    }
    if (best !== null) {
      if (horizontal)
        result.x = rect.x + best.delta;
      else
        result.y = rect.y + best.delta;
      result.guides.push({
                           "vertical": horizontal,
                           "position": best.line
                         });
    } else if (grid > 0) {
      if (horizontal)
        result.x = Math.round(rect.x / grid) * grid;
      else
        result.y = Math.round(rect.y / grid) * grid;
    }
  }
  return result;
}

// Keep a widget partly on the desktop: at least a quarter of it must stay visible.
function clampPosition(x, y, width, height, screenWidth, screenHeight) {
  var minX = width * 0.25;
  var minY = height * 0.25;
  return {
    "x": Math.max(-width + minX, Math.min(x, screenWidth - minX)),
    "y": Math.max(-height + minY, Math.min(y, screenHeight - minY))
  };
}

// Saved data of a new widget: the registry defaults, placed so that its middle is at the given
// desktop point (`guessWidth/Height` is the size it is expected to have, it is moved by the user afterwards).
function newWidget(id, metadata, pointX, pointY, screenWidth, screenHeight) {
  var data = {
    "id": id
  };
  if (metadata) {
    var keys = Object.keys(metadata);
    for (var i = 0; i < keys.length; i++)
      data[keys[i]] = metadata[keys[i]];
  }
  var spot = spotFor(200, 120, pointX, pointY, screenWidth, screenHeight);
  data.x = spot.x;
  data.y = spot.y;
  data.scale = 1.0;
  return data;
}

// Icon of a shelf tile
function tileIcon(id) {
  switch (id) {
  case "Clock":
    return "clock";
  case "MediaPlayer":
    return "music";
  case "Weather":
    return "cloud";
  case "WeatherDetails":
    return "wind";
  case "SystemStat":
    return "cpu";
  case "AudioVisualizer":
    return "chart-bar";
  }
  return String(id).indexOf("plugin:") === 0 ? "plug" : "layout-grid-add";
}
