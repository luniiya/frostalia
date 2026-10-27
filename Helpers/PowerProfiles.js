.pragma library

// Translation key for a power profile's name, with the PowerProfile enum values
// passed in (the helper can't import Quickshell)
function labelKey(available, profile, powerSaver, balanced, performance) {
  if (!available)
    return "common.unknown";
  switch (profile) {
  case powerSaver:
    return "common.power-saver";
  case balanced:
    return "common.balanced";
  case performance:
    return "common.performance";
  default:
    return "common.unknown";
  }
}
