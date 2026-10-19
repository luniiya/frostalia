import QtQuick
import QtTest
import "../Commons/Migrations"
import "../Helpers/ColorSchemeNames.js" as ColorSchemeNames

TestCase {
  name: "ColorSchemeNames"

  Migration69 {
    id: migration
  }

  QtObject {
    id: logger
    function i() {}
  }

  function test_names_data() {
    return [
          { tag: "tokyo night", folder: "Tokyo-Night", display: "Tokyo Night" },
          { tag: "rose pine", folder: "Rosepine", display: "Rose Pine" },
          { tag: "noctalia", folder: "Noctalia", display: "Noctalia" },
          { tag: "eldritch", folder: "Eldritch", display: "Eldritch" }
        ];
  }

  function test_names(data) {
    compare(ColorSchemeNames.displayName(data.folder), data.display);
    compare(ColorSchemeNames.folderName(data.display), data.folder);
  }

  function test_defaultScheme() {
    compare(ColorSchemeNames.defaultScheme, "Eldritch");
  }

  function test_migration_data() {
    return [
          { tag: "frostalia default", saved: "Frostalia (default)", expected: "Noctalia" },
          { tag: "frostalia legacy", saved: "Frostalia (legacy)", expected: "Noctalia" },
          { tag: "other scheme", saved: "Rose Pine", expected: "Rose Pine" }
        ];
  }

  function test_migration(data) {
    const adapter = { colorSchemes: { predefinedScheme: data.saved } };
    verify(migration.migrate(adapter, logger, { colorSchemes: { predefinedScheme: data.saved } }));
    compare(adapter.colorSchemes.predefinedScheme, data.expected);
  }

  function test_migrationWithoutSchemeIsNoop() {
    const adapter = { colorSchemes: { predefinedScheme: "Eldritch" } };
    verify(migration.migrate(adapter, logger, {}));
    compare(adapter.colorSchemes.predefinedScheme, "Eldritch");
  }
}
