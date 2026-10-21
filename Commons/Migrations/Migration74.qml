import QtQuick
import "../../Helpers/BubbleLogic.js" as BubbleLogic

QtObject {
  function migrate(adapter, logger, rawJson) {
    logger.i("Settings", "Migrating settings to v74 (overlay bubbles by default)");
    adapter.bubbles.defaults.reserveSpace = false;
    adapter.bubbles.configurations = BubbleLogic.migrateOverlayConfigurations(adapter.bubbles.configurations);
    return true;
  }
}
