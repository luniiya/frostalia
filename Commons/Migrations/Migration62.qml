import QtQuick
import "../../Helpers/RemovedWidgets.js" as RemovedWidgets

QtObject {
  // Wallpapers are left to the system wallpaper daemon: drop the wallpaper selector widget
  function migrate(adapter, logger, rawJson) {
    logger.i("Settings", "Migrating settings to v62 (remove WallpaperSelector)");
    const ids = ["WallpaperSelector"];

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
