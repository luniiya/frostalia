import QtQuick
import "../../Helpers/BarContextMenu.js" as BarContextMenu

QtObject {
  function migrate(adapter, logger, rawJson) {
    logger.i("Settings", "Migrating settings to v72 (bar context menu by default)");
    adapter.bar.rightClickAction = BarContextMenu.migrateRightClickAction(rawJson?.bar?.rightClickAction);
    return true;
  }
}
