.pragma library

// Apply only declared settings to the QML model. Unknown TOML keys stay on disk.
function apply(target, values) {
  if (!values || typeof values !== "object")
    return;
  for (var key of Object.keys(values)) {
    if (!(key in target) || typeof target[key] === "function")
      continue;
    var value = values[key];
    if (value && typeof value === "object" && !Array.isArray(value)) {
      if (target[key] && typeof target[key] === "object")
        apply(target[key], value);
    } else {
      target[key] = value;
    }
  }
}

// Capture UI edits made while a read was in flight, so a reload cannot erase them.
function changes(before, after) {
  var result = {};
  for (var key of Object.keys(after)) {
    var value = after[key];
    var previous = before ? before[key] : undefined;
    if (JSON.stringify(previous) === JSON.stringify(value))
      continue;
    if (value && typeof value === "object" && !Array.isArray(value) && previous && typeof previous === "object" && !Array.isArray(previous))
      result[key] = changes(previous, value);
    else
      result[key] = value;
  }
  return result;
}
