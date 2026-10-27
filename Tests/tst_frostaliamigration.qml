import QtQuick
import QtTest
import "../Commons/Migrations"
import "../Helpers/ShellRename.js" as ShellRename

TestCase {
  name: "FrostaliaMigration"

  Migration65 {
    id: migration
  }

  function adapter() {
    return {
      bar: {
        widgets: {
          left: [],
          center: [],
          right: []
        },
        screenOverrides: []
      },
      controlCenter: {
        shortcuts: {
          left: [],
          right: []
        }
      },
      ecoMode: {
        disableDesktopWidgets: false
      },
      colorSchemes: {
        predefinedScheme: "Frostalia (default)"
      }
    };
  }

  function test_copiedNoctaliaaSettings() {
    var saved = {
      bar: {
        widgets: {
          left: [
            {
              id: "NoctaliaaPerformance"
            }
          ],
          right: [
            {
              id: "Battery",
              showNoctaliaaPerformance: true
            }
          ]
        },
        screenOverrides: [
          {
            name: "eDP-1",
            widgets: {
              center: [
                {
                  id: "NoctaliaaPerformance"
                }
              ]
            }
          }
        ]
      },
      controlCenter: {
        shortcuts: {
          left: [
            {
              id: "NoctaliaaPerformance"
            }
          ]
        }
      },
      noctaliaaPerformance: {
        disableDesktopWidgets: true
      },
      colorSchemes: {
        predefinedScheme: "Noctalia (legacy)"
      }
    };
    var target = adapter();
    verify(migration.migrate(target, {
                               i: function () {}
                             }, saved));
    compare(target.bar.widgets.left[0].id, "FrostaliaPerformance");
    compare(target.bar.widgets.right[0].showFrostaliaPerformance, true);
    compare(target.bar.screenOverrides[0].widgets.center[0].id, "FrostaliaPerformance");
    compare(target.controlCenter.shortcuts.left[0].id, "FrostaliaPerformance");
    compare(target.ecoMode.disableDesktopWidgets, true);
    compare(target.colorSchemes.predefinedScheme, "Frostalia (legacy)");
    compare(saved.bar.widgets.left[0].id, "NoctaliaaPerformance");
  }

  function test_preservesCustomSchemeAndFalseSetting() {
    var target = adapter();
    target.ecoMode.disableDesktopWidgets = true;
    target.colorSchemes.predefinedScheme = "Noctalia custom";
    verify(migration.migrate(target, {
                               i: function () {}
                             }, {
                               noctaliaaPerformance: {
                                 disableDesktopWidgets: false
                               },
                               colorSchemes: {
                                 predefinedScheme: "Noctalia custom"
                               }
                             }));
    compare(target.ecoMode.disableDesktopWidgets, false);
    compare(target.colorSchemes.predefinedScheme, "Noctalia custom");
  }

  function test_currentSettingsRemainIdentical() {
    var current = [
          {
            id: "FrostaliaPerformance"
          },
          {
            id: "Battery",
            showFrostaliaPerformance: false
          }
        ];
    verify(ShellRename.renameValue(current) === current);
    verify(migration.migrate(adapter(), {
                               i: function () {}
                             }, {}));
  }
}
