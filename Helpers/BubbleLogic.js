.pragma library

function isBubbleSection(section) {
  return typeof section === "string" && section.indexOf("bubble:") === 0;
}

function widgetBackground(section, color) {
  return isBubbleSection(section) ? "transparent" : color;
}

function backgroundColor(configuration, themedColor) {
  return configuration.oledMode ? "#000000" : themedColor;
}

function backgroundOpacity(configuration) {
  return configuration.oledMode ? 1 : configuration.opacity;
}

function sectionId(id) {
  return "bubble:" + id;
}

function itemContext(item) {
  for (var current = item; current; current = current.parent) {
    if (current.bubbleContext)
      return current.bubbleContext;
  }
  return null;
}

function isOledItem(item) {
  var context = itemContext(item);
  return context !== null && context.oledMode === true;
}

function panelPosition(button, position, width, height, screenWidth, screenHeight, margin) {
  var x = button.x + (button.width - width) / 2;
  var y = button.y + (button.height - height) / 2;
  if (position === "left") x = button.x + button.width + margin;
  else if (position === "right") x = button.x - width - margin;
  else if (position === "bottom") y = button.y - height - margin;
  else y = button.y + button.height + margin;
  return { x: bounded(x, margin, margin, Math.max(margin, screenWidth - width - margin)), y: bounded(y, margin, margin, Math.max(margin, screenHeight - height - margin)) };
}

function find(configurations, monitor, id) {
  return (configurations || []).find(function (bubble) {
    return bubble.monitor === monitor && bubble.id === id;
  }) || null;
}

function forMonitor(configurations, monitor) {
  return (configurations || []).filter(function (bubble) {
    return bubble.monitor === monitor;
  });
}

function bounded(value, fallback, minimum, maximum) {
  var number = Number(value);
  if (value === undefined || value === null || !isFinite(number))
    number = fallback;
  return Math.max(minimum, Math.min(maximum, number));
}

function effective(bubble, defaults) {
  var result = Object.assign({}, defaults, bubble || {});
  result.oledMode = result.oledMode === true;
  if (["top", "bottom", "left", "right"].indexOf(result.position) < 0)
    result.position = "top";
  if (["start", "center", "end"].indexOf(result.alignment) < 0)
    result.alignment = "end";
  if (["floating", "attached", "notch"].indexOf(result.style) < 0)
    result.style = "floating";
  if (["up", "down", "left", "right", "fade", "none"].indexOf(result.transition) < 0)
    result.transition = "up";
  if (["none", "primary", "secondary", "tertiary", "error", "outline"].indexOf(result.backgroundColorKey) < 0)
    result.backgroundColorKey = "none";
  result.height = bounded(result.height, 34, 20, 100);
  result.padding = bounded(result.padding, 4, 0, 40);
  result.margin = bounded(result.margin, 8, 0, 200);
  result.spacing = bounded(result.spacing, 8, 0, 100);
  result.offset = bounded(result.offset, 0, -10000, 10000);
  result.radius = bounded(result.radius, 16, 0, 50);
  result.opacity = bounded(result.opacity, 0.93, 0, 1);
  result.cycleInterval = bounded(result.cycleInterval, 5, 1, 300);
  result.transitionDuration = bounded(result.transitionDuration, 220, 0, 2000);
  // JsonAdapter exposes saved arrays as QML sequences, which fail Array.isArray.
  result.widgets = result.widgets && typeof result.widgets.length === "number" ? Array.prototype.slice.call(result.widgets) : [];
  return result;
}

function nextIndex(index, count, step) {
  if (!(count > 0))
    return 0;
  return ((index + step) % count + count) % count;
}

// Touchpads can use either axis. A mouse's vertical wheel works with every animation.
// Accumulate small deltas into one step rather than cycling on every touchpad event.
function wheelStep(accumulator, x, y, pixelDelta) {
  var delta = Math.abs(x) > Math.abs(y) ? x : y;
  if (!delta)
    return { accumulator: accumulator, step: 0 };
  if (accumulator * delta < 0)
    accumulator = 0;
  accumulator += delta;
  var threshold = pixelDelta ? 40 : 120;
  if (Math.abs(accumulator) < threshold)
    return { accumulator: accumulator, step: 0 };
  return { accumulator: 0, step: accumulator < 0 ? 1 : -1 };
}

function animationVector(direction, step) {
  var sign = step < 0 ? -1 : 1;
  switch (direction) {
  case "up": return { x: 0, y: -sign };
  case "down": return { x: 0, y: sign };
  case "left": return { x: -sign, y: 0 };
  case "right": return { x: sign, y: 0 };
  default: return { x: 0, y: 0 };
  }
}

function shouldShow(enabled, widgetCount, hideOnFullscreen, fullscreen) {
  return enabled && widgetCount > 0 && !(hideOnFullscreen && fullscreen);
}

function shouldAutoCycle(visible, automatic, count, hovered, panelOpen) {
  return visible && automatic && count > 1 && !hovered && !panelOpen;
}

function hasFullscreen(toplevels, monitor) {
  return (toplevels || []).some(function (window) {
    return window.fullscreen && !window.minimized && (window.screens || []).some(function (screen) {
      return screen.name === monitor;
    });
  });
}

function wantsPanels(enabled, configurations, monitor) {
  return enabled && forMonitor(configurations, monitor).some(function (bubble) {
    return (bubble.widgets || []).length > 0;
  });
}

// Immutable editing keeps JsonAdapter and QML bindings reactive; widget settings never
// leak into a bar or another bubble that happens to contain the same widget type.
function update(configurations, monitor, id, patch) {
  return (configurations || []).map(function (bubble) {
    return bubble.monitor === monitor && bubble.id === id ? Object.assign({}, bubble, patch) : bubble;
  });
}

function updateWidget(configurations, monitor, id, index, settings) {
  var bubble = find(configurations, monitor, id);
  if (!bubble || index < 0 || index >= (bubble.widgets || []).length)
    return configurations;
  var widgets = bubble.widgets.slice();
  widgets[index] = Object.assign({}, widgets[index], settings);
  return update(configurations, monitor, id, { widgets: widgets });
}

function reorder(widgets, from, to) {
  var result = (widgets || []).slice();
  if (from < 0 || to < 0 || from >= result.length || to >= result.length)
    return result;
  result.splice(to, 0, result.splice(from, 1)[0]);
  return result;
}

function moveBubble(configurations, monitor, id, step) {
  var result = (configurations || []).slice();
  var positions = [];
  var current = -1;
  result.forEach(function (bubble, index) {
    if (bubble.monitor !== monitor)
      return;
    if (bubble.id === id)
      current = positions.length;
    positions.push(index);
  });
  var target = current + step;
  if (current < 0 || target < 0 || target >= positions.length)
    return result;
  // Reorder this monitor's bubbles while preserving other monitors' entries.
  var bubbles = positions.map(function (index) { return result[index]; });
  bubbles = reorder(bubbles, current, target);
  positions.forEach(function (index, offset) { result[index] = bubbles[offset]; });
  return result;
}

function settingPath(item, label) {
  if (!item)
    return null;
  if (item.label === label)
    return [item];
  var children = item.children || [];
  for (var i = 0; i < children.length; i++) {
    var path = settingPath(children[i], label);
    if (path)
      return [item].concat(path);
  }
  return null;
}

function revealSetting(item, label) {
  var path = settingPath(item, label) || [];
  var changed = false;
  path.forEach(function (ancestor) {
    if (ancestor.expanded === false) {
      ancestor.expanded = true;
      changed = true;
    }
  });
  return changed;
}

function isVertical(position) {
  return position === "left" || position === "right";
}

function widgetExtent(item, property, preserveHidden) {
  return item && (item.visible || preserveHidden) ? Math.round(item[property]) : 0;
}

function notchFlare(configuration) {
  return configuration.style === "notch" ? Math.min(configuration.radius, configuration.height / 2) : 0;
}

function contentSize(widget, configuration) {
  var vertical = isVertical(configuration.position);
  var flare = notchFlare(configuration);
  var inset = configuration.padding * 2 + flare * 2;
  return {
    width: Math.ceil(Math.max(configuration.height, widgetExtent(widget, "implicitWidth", true)) + (vertical ? 0 : inset)),
    height: Math.ceil(Math.max(configuration.height, widgetExtent(widget, "implicitHeight", true)) + (vertical ? inset : 0))
  };
}

function bodyRect(configuration, width, height) {
  var vertical = isVertical(configuration.position);
  var inset = Math.min(notchFlare(configuration), (vertical ? height : width) / 4, (vertical ? width : height) / 2);
  return {
    x: vertical ? 0 : inset,
    y: vertical ? inset : 0,
    width: width - (vertical ? 0 : inset * 2),
    height: height - (vertical ? inset * 2 : 0)
  };
}

function cornerAttachment(placement, position, screenWidth, screenHeight) {
  var vertical = isVertical(position);
  var start = vertical ? placement.y : placement.x;
  var end = start + (vertical ? placement.height : placement.width);
  var length = vertical ? screenHeight : screenWidth;
  var atStart = start <= 0;
  var atEnd = end >= length;
  return atStart && atEnd ? "both" : atStart ? "start" : atEnd ? "end" : "";
}

// Bubbles sharing an edge and alignment form a row (or a column on side edges).
// Align widget centers and measure mixed-style spacing between their bodies.
// Adjacent notches retain room for both flares at the screen edge.
function layout(configurations, defaults, sizes, monitor, id, screenWidth, screenHeight) {
  var bubble = effective(find(configurations, monitor, id), defaults);
  var vertical = isVertical(bubble.position);
  var edgeLength = vertical ? screenHeight : screenWidth;
  var group = forMonitor(configurations, monitor).map(function (entry) {
    return effective(entry, defaults);
  }).filter(function (entry) {
    return entry.position === bubble.position && entry.alignment === bubble.alignment && entry.widgets.length > 0;
  });
  var measurements = group.map(function (entry) {
    var size = sizes[monitor + "|" + entry.id] || { width: entry.height, height: entry.height };
    return {
      width: Math.min(Math.max(1, size.width), Math.max(1, screenWidth)),
      height: Math.min(Math.max(1, size.height), Math.max(1, screenHeight))
    };
  });
  var center = 0;
  group.forEach(function (entry, index) {
    var cross = vertical ? measurements[index].width : measurements[index].height;
    center = Math.max(center, cross / 2 + (entry.style === "floating" ? entry.margin : 0));
  });
  group.forEach(function (entry, index) {
    if (entry.style !== "floating") {
      if (vertical)
        measurements[index].width = Math.min(center * 2, Math.max(1, screenWidth));
      else
        measurements[index].height = Math.min(center * 2, Math.max(1, screenHeight));
    }
  });
  var total = 0;
  var before = 0;
  var found = false;
  group.forEach(function (entry, index) {
    var size = measurements[index];
    if (entry.id === id) {
      before = total;
      found = true;
    }
    total += vertical ? size.height : size.width;
    if (index < group.length - 1) {
      var next = group[index + 1];
      var nextSize = measurements[index + 1];
      var compensation = 0;
      if (entry.style === "notch" && next.style === "floating") {
        var body = bodyRect(entry, size.width, size.height);
        compensation = vertical ? body.y : body.x;
      } else if (entry.style === "floating" && next.style === "notch") {
        var nextBody = bodyRect(next, nextSize.width, nextSize.height);
        compensation = vertical ? nextBody.y : nextBody.x;
      }
      total += entry.spacing - compensation;
    }
  });
  var index = group.findIndex(function (entry) { return entry.id === id; });
  var measured = index >= 0 ? measurements[index] : sizes[monitor + "|" + id] || { width: bubble.height, height: bubble.height };
  var width = Math.min(Math.max(1, measured.width), Math.max(1, screenWidth));
  var height = Math.min(Math.max(1, measured.height), Math.max(1, screenHeight));
  var axisSize = vertical ? height : width;
  var endBubble = group.length > 0 ? group[bubble.alignment === "end" ? group.length - 1 : 0] : bubble;
  var endMargin = endBubble.style === "attached" ? 0 : endBubble.margin;
  var origin = bubble.alignment === "start" ? endMargin : bubble.alignment === "end" ? edgeLength - endMargin - total : (edgeLength - total) / 2;
  var along = bounded(origin + (found ? before : 0) + bubble.offset, 0, 0, Math.max(0, edgeLength - axisSize));
  var gap = bubble.style === "floating" ? (found ? center - (vertical ? width : height) / 2 : bubble.margin) : 0;
  var x = vertical ? (bubble.position === "left" ? gap : screenWidth - gap - width) : along;
  var y = vertical ? along : (bubble.position === "top" ? gap : screenHeight - gap - height);
  return { x: bounded(x, 0, 0, Math.max(0, screenWidth - width)), y: bounded(y, 0, 0, Math.max(0, screenHeight - height)), width: width, height: height };
}

// The same path is rotated/reflected for all four edges. Notches flare into the
// screen edge, attached pills have square edge corners, floating pills are rounded.
function backgroundPath(width, height, radius, style, position, attachment) {
  var vertical = isVertical(position);
  var w = vertical ? height : width;
  var h = vertical ? width : height;
  var r = Math.max(0, Math.min(radius, w / 4, h / 2));
  function point(x, y) {
    if (position === "bottom") return x + " " + (height - y);
    if (position === "left") return y + " " + x;
    if (position === "right") return (width - y) + " " + x;
    return x + " " + y;
  }
  if (r === 0)
    return "M " + point(0, 0) + " L " + point(w, 0) + " L " + point(w, h) + " L " + point(0, h) + " Z";
  if (style === "notch") {
    return "M " + point(0, 0) + " L " + point(w, 0) + " Q " + point(w - r, 0) + " " + point(w - r, r)
        + " L " + point(w - r, h - r) + " Q " + point(w - r, h) + " " + point(w - 2 * r, h)
        + " L " + point(2 * r, h) + " Q " + point(r, h) + " " + point(r, h - r)
        + " L " + point(r, r) + " Q " + point(r, 0) + " " + point(0, 0) + " Z";
  }
  if (style === "attached") {
    var startRadius = attachment === "start" || attachment === "both" ? 0 : r;
    var endRadius = attachment === "end" || attachment === "both" ? 0 : r;
    var path = "M " + point(0, 0) + " L " + point(w, 0) + " L " + point(w, h - endRadius);
    if (endRadius > 0)
      path += " Q " + point(w, h) + " " + point(w - endRadius, h);
    path += " L " + point(startRadius, h);
    if (startRadius > 0)
      path += " Q " + point(0, h) + " " + point(0, h - startRadius);
    return path + " L " + point(0, 0) + " Z";
  }
  var top = style === "floating" ? r : 0;
  return "M " + point(top, 0) + " L " + point(w - top, 0) + " Q " + point(w, 0) + " " + point(w, top)
      + " L " + point(w, h - r) + " Q " + point(w, h) + " " + point(w - r, h)
      + " L " + point(r, h) + " Q " + point(0, h) + " " + point(0, h - r)
      + " L " + point(0, top) + " Q " + point(0, 0) + " " + point(top, 0) + " Z";
}
