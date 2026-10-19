import QtQuick
import "../../Helpers/ColorSchemeNames.js" as ColorSchemeNames

QtObject {
  // The original color scheme is called Noctalia again
  function migrate(adapter, logger, rawJson) {
    logger.i("Settings", "Migrating settings to v69 (rename the Frostalia color scheme to Noctalia)");
    const scheme = rawJson?.colorSchemes?.predefinedScheme;
    const migrated = ColorSchemeNames.migratedName(scheme);
    if (migrated !== scheme)
      adapter.colorSchemes.predefinedScheme = migrated;
    return true;
  }
}
