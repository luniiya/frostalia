.pragma library

// Eco mode is the shell's lite mode (no shadows, animations, desktop widgets or
// notification popups). Power saver forces it on; on the other power profiles
// (Performance behaves exactly like Balanced) the user's own toggle decides.
function forced(available, profile, powerSaverProfile) {
  return !!available && profile === powerSaverProfile;
}

function active(available, profile, powerSaverProfile, manual) {
  return forced(available, profile, powerSaverProfile) || !!manual;
}

// What the toggle does: while forced it can't be turned off, so it is a no-op.
// Returns the new value of the manual setting.
function toggled(available, profile, powerSaverProfile, manual) {
  if (forced(available, profile, powerSaverProfile))
    return !!manual;
  return !manual;
}

// Control center shortcut lists: add the EcoMode tile right after PowerProfile.
// Returns the new list, or null when there is nothing to change.
function withEcoShortcut(list) {
  if (!Array.isArray(list))
    return null;
  let at = -1;
  for (let i = 0; i < list.length; i++) {
    if (list[i] && list[i].id === "EcoMode")
      return null;
    if (list[i] && list[i].id === "PowerProfile")
      at = i;
  }
  if (at < 0)
    return null;
  const copy = list.slice();
  copy.splice(at + 1, 0, { "id": "EcoMode" });
  return copy;
}
