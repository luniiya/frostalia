.pragma library

function deviceKey(node) {
  if (!node) {
    return "";
  }
  return node.name || (node.properties && node.properties["node.name"]) || "";
}

function maxOutputVolume(overdrive, selectedOnly, allowedDevices, node) {
  if (!overdrive) {
    return 1.0;
  }
  if (!selectedOnly) {
    return 1.5;
  }
  const key = deviceKey(node);
  return key && (allowedDevices || []).indexOf(key) !== -1 ? 1.5 : 1.0;
}

function withDeviceAllowed(allowedDevices, node, allowed) {
  const key = deviceKey(node);
  const devices = (allowedDevices || []).filter(value => value !== key);
  if (key && allowed) {
    devices.push(key);
  }
  return devices;
}

function isAboveNormalVolume(volume) {
  return volume > 1.0;
}

function widgetColor(volume, configuredColor, normalColor) {
  const color = String(configuredColor || "").trim();
  if (isAboveNormalVolume(volume) && /^#(?:[0-9a-f]{3}|[0-9a-f]{6})$/i.test(color)) {
    return color;
  }
  return normalColor;
}
