import QtQuick
import "../../Helpers/SessionActions.js" as SessionActions

QtObject {
  function migrate(adapter, logger, rawJson) {
    logger.i("Settings", "Migrating settings to v64 (external lock command)");
    const options = rawJson?.sessionMenu?.powerOptions;
    if (!Array.isArray(options))
      return true;

    const previousLock = options.find(option => option && option.action === "lock");
    const cleaned = SessionActions.withoutLock(options);
    adapter.sessionMenu.powerOptions = SessionActions.withExternalLock(cleaned, previousLock);
    return true;
  }
}
