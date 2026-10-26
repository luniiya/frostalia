import QtQuick
import QtTest
import "../Helpers/UiStyleSettings.js" as UiStyleSettings
import "../Helpers/UiStyles.js" as UiStyles

TestCase {
  name: "UiStyleSettings"

  // The real style folders (Styles/<id>/Definition.qml)
  readonly property var styles: UiStyles.loadAll(Qt.resolvedUrl("../Styles"), ["material", "keycap"])

  function tokens(id) {
    return UiStyles.definition(styles, id).tokens;
  }

  function test_defaultsAndResetValuesAreStyleSpecific() {
    compare(UiStyleSettings.defaultValue(styles, "material", "ui.panelBackgroundOpacity"), 1);
    compare(UiStyleSettings.defaultValue(styles, "unknown", "ui.panelBackgroundOpacity"), 1);
    compare(UiStyleSettings.defaultValue(styles, "material", "ui.frostedGlass"), true);
    compare(UiStyleSettings.defaultValue(styles, "material", "ui.glassPanelOpacity"), 0.85);
    compare(UiStyleSettings.defaultValue(styles, "material", "ui.glassSurfaceOpacity"), 0.7);
    compare(UiStyleSettings.defaultValue(styles, "material", "general.scaleRatio"), undefined);
    compare(UiStyleSettings.defaultValue(styles, "material", "ui.fontDefaultScale"), undefined);
    compare(UiStyleSettings.defaultValue(styles, "material", "general.screenRadiusRatio"), undefined);
    compare(UiStyleSettings.defaultValue(styles, "material", "ui.style"), undefined);
    compare(UiStyleSettings.defaultValue(styles, "material", "ui.fontDefault"), "Roboto");
    compare(UiStyleSettings.defaultValue(styles, "material", "ui.boxBorderEnabled"), false);
    compare(UiStyleSettings.defaultValue(styles, "keycap", "ui.fontDefault"), "Google Sans Flex");
    compare(UiStyleSettings.defaultValue(styles, "keycap", "ui.boxBorderEnabled"), true);
    compare(UiStyleSettings.defaultValue(styles, "keycap", "ui.boxBorderWidth"), 2);
    compare(UiStyleSettings.defaultValue(styles, "keycap", "ui.frostedGlass"), false);
    compare(UiStyleSettings.defaultValue(styles, "keycap", "ui.panelBackgroundOpacity"), 1);
    compare(UiStyleSettings.defaultValue(styles, "keycap", "general.radiusRatio"), 1);
  }

  function test_presetFontsAreDiscoverableWithoutSystemInstallation() {
    compare(UiStyles.fontFamilies(styles).sort(), ["Google Sans Flex", "Roboto"]);
    const families = UiStyles.fontFamilies(styles);
    families[0] = "changed";
    compare(UiStyles.fontFamilies(styles).sort(), ["Google Sans Flex", "Roboto"]);
  }

  function test_squareStyleDefaultsAndIndependentCopies() {
    const definitions = Object.assign({}, styles, {
                                        "squareFixture": {
                                          labelKey: "fixture",
                                          settingsDefaults: {
                                            general: {
                                              radiusRatio: 0,
                                              iRadiusRatio: 0
                                            },
                                            ui: {
                                              fontDefault: "Retro"
                                            }
                                          },
                                          tokens: {}
                                        }
                                      });
    const square = UiStyleSettings.forStyle(definitions, "squareFixture");
    compare(square.general.radiusRatio, 0);
    compare(square.general.iRadiusRatio, 0);
    compare(square.ui.fontDefault, "Retro");
    square.general.radiusRatio = 1.5;
    compare(UiStyleSettings.forStyle(definitions, "squareFixture").general.radiusRatio, 0);
    compare(UiStyleSettings.forStyle(definitions, "keycap").general.radiusRatio, 1);
    const config = UiStyleSettings.configuration("/tmp/settings/UI", definitions);
    compare(config.directory, "/tmp/settings/UI");
    compare(config.default_style, "material");
    compare(config.defaults.squareFixture.general.radiusRatio, 0);
    compare(Object.keys(config.defaults).sort(), ["keycap", "material", "squareFixture"]);
  }
}
