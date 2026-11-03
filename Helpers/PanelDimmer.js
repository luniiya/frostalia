.pragma library

// `panelOpacity`: the open panel's own dimming (SmartPanel.dimmerOpacity); negative or
// missing uses the configured one
function opacity(panelOpen, panelClosing, configuredOpacity, panelOpacity) {
  const wanted = Number.isFinite(panelOpacity) && panelOpacity >= 0 ? panelOpacity : configuredOpacity;
  if (!panelOpen || panelClosing || !Number.isFinite(wanted)) {
    return 0;
  }
  return Math.max(0, Math.min(1, wanted));
}

// Whether MainScreen blurs the whole screen: while a panel that asks for it
// (SmartPanel.blurScreen) is open on that screen and not closing
function screenBlur(panelOpen, panelClosing, wanted) {
  return !!panelOpen && !panelClosing && wanted === true;
}
