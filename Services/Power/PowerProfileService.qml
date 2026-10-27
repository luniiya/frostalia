pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "../../Helpers/EcoMode.js" as EcoMode
import "../../Helpers/PowerProfiles.js" as PowerProfileLabels
import qs.Commons
import qs.Services.UI

Singleton {
  id: root

  readonly property var powerProfiles: PowerProfiles
  readonly property bool available: powerProfiles && powerProfiles.hasPerformanceProfile
  property int profile: powerProfiles ? powerProfiles.profile : PowerProfile.Balanced

  // Not a power profile: the shell's lite mode (no shadows, animations, desktop widgets,
  // notification popups, etc.). Power saver forces it on; otherwise the user's toggle decides.
  // The Performance profile behaves like Balanced here.
  readonly property bool ecoModeForced: EcoMode.forced(available, profile, PowerProfile.PowerSaver)
  readonly property bool ecoMode: EcoMode.active(available, profile, PowerProfile.PowerSaver, Settings.data.ecoMode.enabled)

  function toggleEcoMode() {
    Settings.data.ecoMode.enabled = EcoMode.toggled(available, profile, PowerProfile.PowerSaver, Settings.data.ecoMode.enabled);
  }

  function setEcoMode(value) {
    Settings.data.ecoMode.enabled = !!value;
  }

  function getName(p) {
    if (!available)
      return "Unknown";

    const prof = (p !== undefined) ? p : profile;

    switch (prof) {
    case PowerProfile.Performance:
      return "Performance";
    case PowerProfile.Balanced:
      return "Balanced";
    case PowerProfile.PowerSaver:
      return "Power saver";
    default:
      return "Unknown";
    }
  }

  // Translated profile name, for display
  function getLabel(p) {
    const prof = (p !== undefined) ? p : profile;
    return I18n.tr(PowerProfileLabels.labelKey(available, prof, PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance));
  }

  function getIcon(p) {
    if (!available)
      return "balanced";

    const prof = (p !== undefined) ? p : profile;

    switch (prof) {
    case PowerProfile.Performance:
      return "performance";
    case PowerProfile.Balanced:
      return "balanced";
    case PowerProfile.PowerSaver:
      return "powersaver";
    default:
      return "balanced";
    }
  }

  function init() {
    Logger.d("PowerProfileService", "Service started");
  }

  function setProfile(p) {
    if (!available)
      return;
    try {
      powerProfiles.profile = p;
    } catch (e) {
      Logger.e("PowerProfileService", "Failed to set profile:", e);
    }
  }

  function cycleProfile() {
    if (!available)
      return;
    const current = powerProfiles.profile;
    if (current === PowerProfile.Performance)
      setProfile(PowerProfile.PowerSaver);
    else if (current === PowerProfile.Balanced)
      setProfile(PowerProfile.Performance);
    else if (current === PowerProfile.PowerSaver)
      setProfile(PowerProfile.Balanced);
  }

  function cycleProfileReverse() {
    if (!available)
      return;
    const current = powerProfiles.profile;
    if (current === PowerProfile.Performance)
      setProfile(PowerProfile.Balanced);
    else if (current === PowerProfile.Balanced)
      setProfile(PowerProfile.PowerSaver);
    else if (current === PowerProfile.PowerSaver)
      setProfile(PowerProfile.Performance);
  }

  function isDefault() {
    if (!available)
      return true;
    return (profile === PowerProfile.Balanced);
  }

  Connections {
    target: powerProfiles
    function onProfileChanged() {
      root.profile = powerProfiles.profile;
      // Only show toast if we have a valid profile name (not "Unknown")
      const profileName = root.getName();
      if (profileName !== "Unknown") {
        ToastService.showNotice(I18n.tr("toast.power-profile.profile-name", {
                                          "profile": profileName
                                        }), I18n.tr("toast.power-profile.changed"), profileName.toLowerCase().replace(" ", ""));
      }
    }
  }
}
