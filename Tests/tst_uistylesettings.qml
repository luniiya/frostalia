import QtQuick
import QtTest
import "../Helpers/UiStyleSettings.js" as UiStyleSettings
import "../Helpers/UiStyles.js" as UiStyles

TestCase {
  name: "UiStyleSettings"

  function test_defaultsAndResetValuesAreStyleSpecific() {
    compare(UiStyleSettings.defaultValue("caelestia", "ui.panelBackgroundOpacity"), 0.93);
    compare(UiStyleSettings.defaultValue("material", "ui.panelBackgroundOpacity"), 1);
    compare(UiStyleSettings.defaultValue("unknown", "ui.panelBackgroundOpacity"), 0.93);
    compare(UiStyleSettings.defaultValue("material", "ui.frostedGlass"), true);
    compare(UiStyleSettings.defaultValue("caelestia", "ui.frostedGlass"), false);
    compare(UiStyleSettings.defaultValue("material", "general.scaleRatio"), undefined);
    compare(UiStyleSettings.defaultValue("material", "ui.fontDefaultScale"), undefined);
    compare(UiStyleSettings.defaultValue("material", "general.screenRadiusRatio"), undefined);
    compare(UiStyleSettings.defaultValue("material", "ui.style"), undefined);
    compare(UiStyleSettings.defaultValue("caelestia", "ui.fontDefault"), "Rubik");
    compare(UiStyleSettings.defaultValue("material", "ui.fontDefault"), "Roboto");
    compare(UiStyleSettings.defaultValue("caelestia", "ui.boxBorderEnabled"), true);
    compare(UiStyleSettings.defaultValue("material", "ui.boxBorderEnabled"), false);
  }

  function test_presetFontsAreDiscoverableWithoutSystemInstallation() {
    compare(UiStyles.fontFamilies(), ["Rubik", "Roboto"]);
    const families = UiStyles.fontFamilies();
    families[0] = "changed";
    compare(UiStyles.fontFamilies(), ["Rubik", "Roboto"]);
  }

  function test_squareStyleDefaultsAndIndependentCopies() {
    UiStyles.definitions.squareFixture = {
      labelKey: "fixture",
      settingsDefaults: {
        general: {
          radiusRatio: 0,
          iRadiusRatio: 0
        },
        ui: {
          fontDefault: "Retro"
        }
      }
    };
    try {
      const square = UiStyleSettings.forStyle("squareFixture");
      compare(square.general.radiusRatio, 0);
      compare(square.general.iRadiusRatio, 0);
      compare(square.ui.fontDefault, "Retro");
      square.general.radiusRatio = 1.5;
      compare(UiStyleSettings.forStyle("squareFixture").general.radiusRatio, 0);
      compare(UiStyleSettings.forStyle("caelestia").general.radiusRatio, 1);
      const config = UiStyleSettings.configuration("/tmp/settings/UI");
      compare(config.directory, "/tmp/settings/UI");
      compare(config.default_style, "caelestia");
      compare(config.defaults.squareFixture.general.radiusRatio, 0);
    } finally {
      delete UiStyles.definitions.squareFixture;
    }
  }
}
