.pragma library

// Plugin bar widgets draw their own capsule. When the active style has bar faces,
// BarWidgetLoader draws the style's plain face behind the plugin and clears the
// plugin's capsule backgrounds, so plugins get the style without code of their own.

// A capsule background is a visible, filled rectangle spanning most of the widget
// along the bar and most of the capsule across it.
function isCapsule(candidate, hostWidth, hostHeight, capsuleHeight, vertical) {
  if (!candidate || candidate.visible === false || candidate.radius === undefined || !candidate.border || !candidate.color)
    return false;
  if (candidate.color.a === 0 && !(candidate.border.width > 0))
    return false;
  const along = vertical ? candidate.height : candidate.width;
  const across = vertical ? candidate.width : candidate.height;
  const hostAlong = vertical ? hostHeight : hostWidth;
  return along >= hostAlong * 0.8 && across >= capsuleHeight * 0.6;
}

// Capsule backgrounds among the widget's children and grandchildren. Deeper items
// are the plugin's own content (icon chips, progress bars) and are left alone.
function capsules(host, capsuleHeight, vertical) {
  const found = [];
  if (!host)
    return found;
  const visit = (item, level) => {
    const children = item.children || [];
    for (let i = 0; i < children.length; i++) {
      const child = children[i];
      if (isCapsule(child, host.width, host.height, capsuleHeight, vertical))
        found.push(child);
      else if (level < 2)
        visit(child, level + 1);
    }
  };
  visit(host, 1);
  return found;
}
