import QtQuick
import QtTest
import "../Helpers/SettingsObject.js" as SettingsObject

TestCase {
  name: "SettingsObject"

  function test_reloadResolvesDefaultsWithoutChangingLiveSettings() {
    var defaults = {
      bar: {
        position: "top",
        widgets: []
      },
      darkMode: false
    };
    var current = {
      bar: {
        position: "bottom",
        widgets: [
          {
            id: "Clock"
          }
        ]
      },
      darkMode: true
    };
    var stored = {
      bar: {
        position: "bottom",
        widgets: [
          {
            id: "Clock"
          }
        ]
      },
      darkMode: true,
      unknown: 42
    };
    var resolved = SettingsObject.resolve(defaults, stored);
    compare(resolved, current);
    compare(SettingsObject.changes(current, resolved), {});
    compare(defaults.bar.position, "top");
    compare(defaults.darkMode, false);
  }

  function test_removedSettingReturnsToDefaultAndPreservesInFlightEdit() {
    var defaults = {
      bar: {
        position: "top"
      },
      darkMode: false
    };
    var current = {
      bar: {
        position: "bottom"
      },
      darkMode: true
    };
    var baseline = SettingsObject.resolve(defaults, {
                                            darkMode: true
                                          });
    var desired = SettingsObject.resolve(baseline, {
                                           darkMode: false
                                         });
    compare(baseline, {
              bar: {
                position: "top"
              },
              darkMode: true
            });
    compare(SettingsObject.changes(current, desired), {
              bar: {
                position: "top"
              },
              darkMode: false
            });
  }

  function test_applyDeclaredNestedSettings() {
    var target = {
      bar: {
        position: "top",
        widgets: []
      },
      enabled: true
    };
    SettingsObject.apply(target, {
                           bar: {
                             position: "bottom",
                             widgets: [
                               {
                                 id: "Clock"
                               }
                             ],
                             unknown: true
                           },
                           unknown: "keep on disk"
                         });
    compare(target, {
              bar: {
                position: "bottom",
                widgets: [
                  {
                    id: "Clock"
                  }
                ]
              },
              enabled: true
            });
  }

  function test_inFlightEditsSurviveExternalReload() {
    var before = {
      bar: {
        position: "top",
        widgets: [
          {
            id: "Clock"
          }
        ]
      },
      enabled: false
    };
    var after = {
      bar: {
        position: "bottom",
        widgets: [
          {
            id: "Clock"
          }
        ]
      },
      enabled: false
    };
    var delta = SettingsObject.changes(before, after);
    compare(delta, {
              bar: {
                position: "bottom"
              }
            });
    var reloaded = {
      bar: {
        position: "left",
        widgets: [
          {
            id: "Battery"
          }
        ]
      },
      enabled: true
    };
    SettingsObject.apply(reloaded, delta);
    compare(reloaded, {
              bar: {
                position: "bottom",
                widgets: [
                  {
                    id: "Battery"
                  }
                ]
              },
              enabled: true
            });
  }

  function test_unchangedSettingsHaveNoDelta() {
    var value = {
      list: [],
      nested: {
        enabled: false
      }
    };
    compare(SettingsObject.changes(value, value), {});
  }
}
