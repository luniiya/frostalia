import QtQuick

QtObject {
  function migrate(adapter, logger, rawJson) {
    // The TOML helper writes the active style file before pruning host appearance
    // keys. Mark the new storage layout only after that load succeeds.
    logger.i("Settings", "Migrating settings to v66 (appearance settings per UI style)");
    return true;
  }
}
