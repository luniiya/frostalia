.pragma library

// Frostalia performance mode (no shadows, animations or notification popups)
// follows the Performance power profile instead of having its own toggle.
function enabled(available, profile, performanceProfile) {
  return !!available && profile === performanceProfile;
}
