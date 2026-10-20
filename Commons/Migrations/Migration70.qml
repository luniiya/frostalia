import QtQuick

QtObject {
  function migrate(adapter, logger, rawJson) {
    logger.i("Settings", "Migrating settings to v70 (remove telemetry)");
    // The store's baseline retains the old key, so saving the adapter without
    // that property also deletes it from the host TOML file.
    if (rawJson?.general)
      delete rawJson.general.telemetryEnabled;
    return true;
  }
}
