import QtQuick
import "../../Helpers/SessionActions.js" as SessionActions

QtObject {
  function migrate(adapter, logger, rawJson) {
    logger.i("Settings", "Migrating settings to v63 (remove lock screen)");
    const options = rawJson?.sessionMenu?.powerOptions;
    const cleaned = SessionActions.withoutLock(options);
    if (cleaned !== options)
      adapter.sessionMenu.powerOptions = cleaned;
    return true;
  }
}
