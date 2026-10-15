.pragma library

function withoutLock(options) {
  if (!Array.isArray(options)) {
    return options;
  }
  const filtered = options.filter(option => option && option.action !== "lock");
  return filtered.length === options.length ? options : filtered;
}

function withExternalLock(options, previousLock) {
  if (!Array.isArray(options) || options.some(option => option && option.action === "lock")) {
    return options;
  }
  const lock = previousLock ? Object.assign({}, previousLock) : { action: "lock", enabled: true, keybind: "1" };
  const rest = previousLock ? options : options.map(option => {
    if (!option || !/^\d+$/.test(option.keybind || "")) {
      return option;
    }
    return Object.assign({}, option, { keybind: String(Number(option.keybind) + 1) });
  });
  return [lock].concat(rest);
}
