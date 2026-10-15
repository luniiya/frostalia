.pragma library

function opacity(panelOpen, panelClosing, configuredOpacity) {
  if (!panelOpen || panelClosing || !Number.isFinite(configuredOpacity)) {
    return 0;
  }
  return Math.max(0, Math.min(1, configuredOpacity));
}
