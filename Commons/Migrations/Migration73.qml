import QtQuick
import "../../Helpers/QtObj2JS.js" as QtObj2JS
import "../../Helpers/WeatherWidget.js" as WeatherWidget

QtObject {
  function migrate(adapter, logger, rawJson) {
    logger.i("Settings", "Migrating settings to v73 (separate Weather Details widget)");
    // Use the adapter so the v71 migration has already converted older IDs.
    const monitors = QtObj2JS.qtObjectToPlainObject(adapter.desktopWidgets.monitorWidgets);
    const migrated = WeatherWidget.splitDetailWidgets(monitors);
    if (migrated !== monitors)
      adapter.desktopWidgets.monitorWidgets = migrated;
    return true;
  }
}
