.pragma library

// Material uses a landscape window with a collapsible category sidebar.
function windowMetrics(material, scale) {
  return {
    width: Math.round((material ? 1100 : 840) * scale),
    height: Math.round((material ? 750 : 910) * scale),
    minimumWidth: Math.round((material ? 560 : 500) * scale),
    minimumHeight: Math.round((material ? 520 : 910) * scale)
  };
}

function materialRail(expanded, scale, scrollbarGutter) {
  const progress = Math.max(0, Math.min(1, Number(expanded)));
  return {
    width: Math.round((44 + 180 * progress) * scale) + Math.max(0, scrollbarGutter || 0),
    rowHeight: Math.round(44 * scale),
    rowSpacing: Math.round(5 * scale)
  };
}

function railIconInset(progress, rowHeight, iconWidth, expandedInset) {
  const expansion = Math.max(0, Math.min(1, progress));
  return (1 - expansion) * (rowHeight - iconWidth) / 2 + expansion * expandedInset;
}

function searchWidth(availableWidth, controlsWidth, scale) {
  return Math.max(0, Math.min(360 * scale, availableWidth - 2 * (controlsWidth + 16 * scale)));
}

function escapeAction(searchText, homeVisible) {
  if (String(searchText || "").length > 0)
    return "clearSearch";
  return homeVisible ? "close" : "home";
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
  var cardWidth = Math.max(0, (width - spacing * (columns - 1)) / columns);
  var profileColumns = Math.min(2, columns);
  return {
    columns: columns,
    spacing: spacing,
    cardWidth: cardWidth,
    profileWidth: cardWidth * profileColumns + spacing * (profileColumns - 1)
  };
}

function homeCategories(tabs, generalId, aboutId, wide) {
  const entries = tabs.map((tab, index) => ({ tab: tab, index: index }));
  const general = entries.find(entry => entry.tab.id === generalId) || null;
  const about = entries.find(entry => entry.tab.id === aboutId) || null;
  const promoted = !!(wide && general && about);
  return {
    general: general,
    about: about,
    promoted: promoted,
    grid: promoted ? entries.filter(entry => entry !== general && entry !== about) : entries
  };
}

function profile(displayName, username, osName, osFallback, hostname) {
  return {
    name: String(username || "").trim() || String(displayName || "").trim(),
    hostname: String(hostname || "").trim(),
    os: String(osName || "").trim() || osFallback
  };
}
