.pragma library

// Whether the shell's panels have finished animating, for scripts that screenshot the
// shell (Scripts/dev/ui-screenshots.sh polls `qs -c frostalia ipc call state panels`).
// Kept free of QML dependencies so it can be unit tested (Tests/tst_panelsettle.qml).

// One SmartPanel's phase: "closed", "opening", "open" or "closing"
function phase(panel) {
  if (!panel || !panel.isPanelVisible)
    return "closed";
  if (panel.isClosing)
    return "closing";
  if (!panel.sizeAnimationComplete || panel.opacity < 1)
    return "opening";
  return "open";
}

// Panel object names carry the screen ("controlCenterPanel-eDP-1"); report the panel only
function panelName(objectName) {
  const name = String(objectName || "");
  const dash = name.indexOf("-");
  return dash > 0 ? name.slice(0, dash) : name;
}

// Settled shell state: "open:<surface>" once something finished opening, "closed" once
// nothing is open or animating, otherwise "busy".
// shell: {
//   opened, closing:      PanelService's SmartPanels
//   settingsWindowOpen:   the settings window
//   overlayLauncherOpen:  the launcher on the overview layer (not a SmartPanel)
//   popupMenuOpen:        a context or tray menu
//   radialMenuOpen:       the desktop radial menu
//   editDesktopProgress:  Edit Desktop's enter/leave animation, 0 (off) to 1 (on)
// }
function state(shell) {
  const s = shell || {};
  if (s.closing)
    return "busy";
  // Menus open on top of panels (the tray drawer's menus)
  if (s.popupMenuOpen)
    return "open:popupMenu";
  if (s.opened)
    return phase(s.opened) === "open" ? "open:" + panelName(s.opened.objectName) : "busy";
  const edit = s.editDesktopProgress || 0;
  if (edit >= 1)
    return "open:editDesktop";
  if (edit > 0)
    return "busy";
  if (s.radialMenuOpen)
    return "open:radialMenu";
  if (s.overlayLauncherOpen)
    return "open:launcherOverlay";
  return s.settingsWindowOpen ? "open:settingsWindow" : "closed";
}
