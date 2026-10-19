.pragma library

var defaultOrder = ["claude", "codex", "copilot", "gemini", "openrouter", "zen"];

// Sort items by their id's position in the saved order. Ids missing from the
// order keep their default position after the ordered ones.
function sortByOrder(items, order, idOf) {
  const saved = Array.isArray(order) ? order : [];
  const rank = id => {
    const index = saved.indexOf(id);
    return index !== -1 ? index : saved.length + defaultOrder.indexOf(id);
  };
  return items.slice().sort((a, b) => rank(idOf(a)) - rank(idOf(b)));
}

function orderedIds(order) {
  return sortByOrder(defaultOrder, order, id => id);
}

function moved(order, fromIndex, toIndex) {
  const ids = orderedIds(order);
  if (fromIndex < 0 || fromIndex >= ids.length || toIndex < 0 || toIndex >= ids.length)
    return ids;
  const id = ids.splice(fromIndex, 1)[0];
  ids.splice(toIndex, 0, id);
  return ids;
}
