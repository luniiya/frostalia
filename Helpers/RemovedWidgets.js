.pragma library

// Dropping widgets that no longer exist from saved layouts (see Commons/Migrations/Migration62.qml).
// Kept free of QML dependencies so it can be unit tested (see Tests/tst_removedwidgets.qml).

// Widget list without entries whose id is in `ids`; the same list when nothing was removed
function withoutWidgets(list, ids) {
  if (!Array.isArray(list))
    return list;
  var kept = list.filter(function (w) {
    return !(w && ids.indexOf(w.id) !== -1);
  });
  return kept.length === list.length ? list : kept;
}

// { left, center, right } sections with the widgets removed; the same object when unchanged
function withoutWidgetsInSections(sections, ids) {
  if (!sections || typeof sections !== "object")
    return sections;
  var out = {};
  var changed = false;
  for (var key in sections) {
    out[key] = withoutWidgets(sections[key], ids);
    if (out[key] !== sections[key])
      changed = true;
  }
  return changed ? out : sections;
}
