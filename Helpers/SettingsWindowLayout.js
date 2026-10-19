.pragma library

// Material uses a landscape window with a collapsible category sidebar.
function windowMetrics(material, scale) {
  return {
    width: Math.round((material ? 1100 : 840) * scale),
    height: Math.round((material ? 750 : 910) * scale),
    minimumWidth: Math.round((material ? 760 : 840) * scale),
    minimumHeight: Math.round((material ? 520 : 910) * scale)
  };
}

function materialRail(expanded, scale, scrollbarGutter) {
  return {
    width: Math.round((expanded ? 224 : 56) * scale) + Math.max(0, scrollbarGutter || 0),
    rowHeight: Math.round((expanded ? 44 : 56) * scale)
  };
}

function searchWidth(availableWidth, controlsWidth, scale) {
  return Math.max(0, Math.min(360 * scale, availableWidth - 2 * (controlsWidth + 16 * scale)));
}


// Both styles navigate directly through the same ordered settings categories.
function adjacentTab(index, count, fromHome, direction) {
  if (count <= 0)
    return -1;
  if (fromHome)
    return direction < 0 ? count - 1 : 0;
  return (index + direction + count) % count;
}

function homeMetrics(availableWidth, scale, material) {
  return {
    contentWidth: Math.max(0, Math.min(availableWidth, Math.round((material ? 960 : 900) * scale))),
    avatarSize: Math.round(56 * scale)
  };
}

function homeGrid(width, scale, material) {
  var spacing = Math.round((material ? 16 : 13) * scale);
  var minimumWidth = Math.round((material ? 210 : 160) * scale);
  var columns = Math.max(1, Math.min(3, Math.floor((width + spacing) / (minimumWidth + spacing))));
  return { columns: columns, spacing: spacing, cardWidth: Math.max(0, (width - spacing * (columns - 1)) / columns) };
}

function profile(displayName, username, osName, osFallback) {
  return {
    name: String(displayName || "").trim() || String(username || "").trim(),
    os: String(osName || "").trim() || osFallback
  };
}
