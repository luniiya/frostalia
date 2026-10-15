import QtQuick
import "../../Helpers/ControlCenterLayout.js" as ControlCenterLayout

QtObject {
  function migrate(adapter, logger, rawJson) {
    logger.i("Settings", "Migrating settings to v67 (configurable control center notifications and calendar)");
    adapter.controlCenter.cards = ControlCenterLayout.withAdditionalCards(adapter.controlCenter.cards);
    return true;
  }
}
