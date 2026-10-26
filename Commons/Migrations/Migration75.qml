import QtQuick
import "../../Helpers/BatteryLiquid.js" as BatteryLiquid

QtObject {
  function migrate(adapter, logger, rawJson) {
    logger.i("Settings", "Migrating settings to v75 (liquid Battery widget)");

    const widgets = rawJson?.bar?.widgets;
    if (widgets) {
      const sections = BatteryLiquid.migrateDisplayMode(widgets);
      if (sections) {
        for (const key of ["left", "center", "right"]) {
          if (sections[key] !== undefined)
            adapter.bar.widgets[key] = sections[key];
        }
      }
    }

    const overrides = rawJson?.bar?.screenOverrides;
    if (BatteryLiquid.isList(overrides)) {
      let changed = false;
      const newOverrides = Array.prototype.map.call(overrides, o => {
        const sections = o ? BatteryLiquid.migrateDisplayMode(o.widgets) : null;
        if (!sections)
          return o;
        changed = true;
        return Object.assign({}, o, {
                               "widgets": sections
                             });
      });
      if (changed)
        adapter.bar.screenOverrides = newOverrides;
    }
    return true;
  }
}
