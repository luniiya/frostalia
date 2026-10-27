import QtQuick
import "../../Helpers/EcoMode.js" as EcoMode

QtObject {
  // Performance mode became eco mode: the Performance profile no longer enables it, power
  // saver forces it. Carry over the options and hooks and add the toggle tile.
  function migrate(adapter, logger, rawJson) {
    logger.i("Settings", "Migrating settings to v76 (eco mode)");

    const perf = rawJson?.frostaliaPerformance;
    if (perf && typeof perf.disableDesktopWidgets === "boolean")
      adapter.ecoMode.disableDesktopWidgets = perf.disableDesktopWidgets;

    const hooks = rawJson?.hooks;
    if (hooks) {
      if (typeof hooks.performanceModeEnabled === "string")
        adapter.hooks.ecoModeEnabled = hooks.performanceModeEnabled;
      if (typeof hooks.performanceModeDisabled === "string")
        adapter.hooks.ecoModeDisabled = hooks.performanceModeDisabled;
    }

    const shortcuts = rawJson?.controlCenter?.shortcuts;
    if (shortcuts) {
      for (const key of ["left", "right"]) {
        const list = EcoMode.withEcoShortcut(shortcuts[key]);
        if (list)
          adapter.controlCenter.shortcuts[key] = list;
      }
    }
    return true;
  }
}
