import QtQuick
import QtTest
import "../Helpers/SettingsObject.js" as SettingsObject

TestCase {
  name: "SettingsObject"

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
