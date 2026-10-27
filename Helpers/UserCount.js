.pragma library

// Who is using a service, as { id: count }. Two instances can share an id (a desktop
// widget and its copy on the Edit Desktop card), so an id only goes away once every
// instance that added it has removed it. Both return a new object, for QML bindings.

function add(users, id) {
  var next = Object.assign({}, users || {});
  next[id] = (next[id] || 0) + 1;
  return next;
}

function remove(users, id) {
  var next = Object.assign({}, users || {});
  if (!next[id])
    return next;
  if (next[id] > 1)
    next[id] -= 1;
  else
    delete next[id];
  return next;
}
