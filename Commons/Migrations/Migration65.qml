import QtQuick
import "../../Helpers/ShellRename.js" as ShellRename

QtObject {
  // The shell was renamed to Frostalia: rename the performance mode widget, its
  // Battery widget toggle and its settings section
  function migrate(adapter, logger, rawJson) {
    logger.i("Settings", "Migrating settings to v65 (Noctaliaa → Frostalia)");

    const widgets = rawJson?.bar?.widgets;
    if (widgets) {
      for (const key of ["left", "center", "right"]) {
        const renamed = ShellRename.renameValue(widgets[key]);
        if (renamed !== widgets[key])
          adapter.bar.widgets[key] = renamed;
      }
    }

    const overrides = rawJson?.bar?.screenOverrides;
    const renamedOverrides = ShellRename.renameValue(overrides);
    if (Array.isArray(overrides) && renamedOverrides !== overrides)
      adapter.bar.screenOverrides = renamedOverrides;

    const shortcuts = rawJson?.controlCenter?.shortcuts;
    if (shortcuts) {
      for (const key of ["left", "right"]) {
        const renamed = ShellRename.renameValue(shortcuts[key]);
        if (renamed !== shortcuts[key])
          adapter.controlCenter.shortcuts[key] = renamed;
      }
    }

    const perf = rawJson?.noctaliaaPerformance || rawJson?.noctaliaPerformance;
    if (perf) {
      for (const key of ["disableDesktopWidgets"]) {
        if (typeof perf[key] === "boolean")
          adapter.frostaliaPerformance[key] = perf[key];
      }
    }

    const scheme = rawJson?.colorSchemes?.predefinedScheme;
    if (scheme === "Noctalia (default)" || scheme === "Noctalia (legacy)")
      adapter.colorSchemes.predefinedScheme = scheme.replace("Noctalia", "Frostalia");

    return true;
  }
}
