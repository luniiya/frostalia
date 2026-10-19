import QtQuick
import "../../Helpers/WeatherWidget.js" as WeatherWidget

QtObject {
  function migrate(adapter, logger, rawJson) {
    logger.i("Settings", "Migrating settings to v71 (one weather widget with selectable views)");
    const monitors = rawJson?.desktopWidgets?.monitorWidgets;
    const migrated = WeatherWidget.migrateDesktopWidgets(monitors);
    if (migrated !== monitors)
      adapter.desktopWidgets.monitorWidgets = migrated;
    return true;
  }
}
