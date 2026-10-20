import QtQuick
import "../../Helpers/RemovedWidgets.js" as RemovedWidgets

QtObject {
  // Performance mode follows the Performance power profile: drop its toggle widgets
  function migrate(adapter, logger, rawJson) {
    logger.i("Settings", "Migrating settings to v68 (remove the Frostalia performance toggle)");
    const ids = ["FrostaliaPerformance"];

    const widgets = rawJson?.bar?.widgets;
    const newWidgets = RemovedWidgets.withoutWidgetsInSections(widgets, ids);
    if (newWidgets !== widgets) {
      for (const key of ["left", "center", "right"]) {
        if (newWidgets[key] !== widgets[key])
          adapter.bar.widgets[key] = newWidgets[key];
      }
    }

    const overrides = rawJson?.bar?.screenOverrides;
    if (Array.isArray(overrides)) {
      let changed = false;
      const newOverrides = overrides.map(o => {
        const w = o ? RemovedWidgets.withoutWidgetsInSections(o.widgets, ids) : undefined;
        if (!o || w === o.widgets)
          return o;
        changed = true;
        return Object.assign({}, o, {
                               "widgets": w
                             });
      });
      if (changed)
        adapter.bar.screenOverrides = newOverrides;
    }

    const shortcuts = rawJson?.controlCenter?.shortcuts;
    const newShortcuts = RemovedWidgets.withoutWidgetsInSections(shortcuts, ids);
    if (newShortcuts !== shortcuts) {
      for (const key of ["left", "right"]) {
        if (newShortcuts[key] !== shortcuts[key])
          adapter.controlCenter.shortcuts[key] = newShortcuts[key];
      }
    }

    return true;
  }
}
