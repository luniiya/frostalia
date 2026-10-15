import QtQuick

QtObject {
  id: root

  // Migrate from version < 27 to version 27
  // Used to convert settingsPanelAttachToBar into settingsPanelMode. Settings now
  // always open in their own window and settingsPanelMode no longer exists, so
  // there is nothing left to migrate.
  function migrate(adapter, logger, rawJson) {
    logger.i("Settings", "Migrating settings to v27");
    return true;
  }
}
