import QtQuick
import QtTest
import "../Commons/Migrations"
import "../Helpers/EcoMode.js" as EcoMode

TestCase {
  name: "EcoMode"

  // Stand-ins for PowerProfile.PowerSaver, Balanced and Performance
  readonly property int powerSaver: 0
  readonly property int balanced: 1
  readonly property int performance: 2

  Migration68 {
    id: migration
  }

  QtObject {
    id: logger
    function i() {
    }
  }

  QtObject {
    id: fakeAdapter
    property var ecoMode: ({
                             "disableDesktopWidgets": true
                           })
    property var hooks: ({})
    property var controlCenter: ({
                                   "shortcuts": {}
                                 })
  }

  Migration76 {
    id: migration76
  }

  function test_active_data() {
    return [
          {
            tag: "performance behaves like balanced",
            available: true,
            profile: performance,
            manual: false,
            forced: false,
            active: false
          },
          {
            tag: "balanced",
            available: true,
            profile: balanced,
            manual: false,
            forced: false,
            active: false
          },
          {
            tag: "balanced manual on",
            available: true,
            profile: balanced,
            manual: true,
            forced: false,
            active: true
          },
          {
            tag: "performance manual on",
            available: true,
            profile: performance,
            manual: true,
            forced: false,
            active: true
          },
          {
            tag: "power saver forces",
            available: true,
            profile: powerSaver,
            manual: false,
            forced: true,
            active: true
          },
          {
            tag: "power saver with manual on",
            available: true,
            profile: powerSaver,
            manual: true,
            forced: true,
            active: true
          },
          {
            tag: "no power profiles, manual off",
            available: false,
            profile: powerSaver,
            manual: false,
            forced: false,
            active: false
          },
          {
            tag: "no power profiles, manual on",
            available: false,
            profile: powerSaver,
            manual: true,
            forced: false,
            active: true
          }
        ];
  }

  function test_active(data) {
    compare(EcoMode.forced(data.available, data.profile, powerSaver), data.forced);
    compare(EcoMode.active(data.available, data.profile, powerSaver, data.manual), data.active);
  }

  function test_toggled() {
    compare(EcoMode.toggled(true, balanced, powerSaver, false), true);
    compare(EcoMode.toggled(true, performance, powerSaver, true), false);
    // forced by power saver: the toggle keeps the saved choice
    compare(EcoMode.toggled(true, powerSaver, powerSaver, false), false);
    compare(EcoMode.toggled(true, powerSaver, powerSaver, true), true);
    compare(EcoMode.toggled(false, powerSaver, powerSaver, false), true);
  }

  function test_withEcoShortcut() {
    compare(EcoMode.withEcoShortcut([
                                      {
                                        id: "Notifications"
                                      },
                                      {
                                        id: "PowerProfile"
                                      },
                                      {
                                        id: "KeepAwake"
                                      }
                                    ]).map(e => e.id), ["Notifications", "PowerProfile", "EcoMode", "KeepAwake"]);
    compare(EcoMode.withEcoShortcut([
                                      {
                                        id: "PowerProfile"
                                      },
                                      {
                                        id: "EcoMode"
                                      }
                                    ]), null);
    compare(EcoMode.withEcoShortcut([
                                      {
                                        id: "Network"
                                      }
                                    ]), null);
    compare(EcoMode.withEcoShortcut(undefined), null);
  }

  function test_migration76() {
    var raw = {
      frostaliaPerformance: {
        disableDesktopWidgets: false
      },
      hooks: {
        performanceModeEnabled: "a",
        performanceModeDisabled: "b"
      },
      controlCenter: {
        shortcuts: {
          left: [
            {
              id: "Network"
            }
          ],
          right: [
            {
              id: "PowerProfile"
            }
          ]
        }
      }
    };
    verify(migration76.migrate(fakeAdapter, logger, raw));
    compare(fakeAdapter.ecoMode.disableDesktopWidgets, false);
    compare(fakeAdapter.hooks.ecoModeEnabled, "a");
    compare(fakeAdapter.hooks.ecoModeDisabled, "b");
    compare(fakeAdapter.controlCenter.shortcuts.right.map(e => e.id), ["PowerProfile", "EcoMode"]);
    compare(fakeAdapter.controlCenter.shortcuts.left, undefined);
  }

  function test_migrationDropsToggles() {
    var saved = {
      bar: {
        widgets: {
          left: [
            {
              id: "FrostaliaPerformance"
            },
            {
              id: "Clock"
            }
          ],
          center: [],
          right: []
        },
        screenOverrides: [
          {
            name: "eDP-1",
            widgets: {
              left: [],
              center: [
                {
                  id: "FrostaliaPerformance"
                }
              ],
              right: []
            }
          }
        ]
      },
      controlCenter: {
        shortcuts: {
          left: [
            {
              id: "Network"
            },
            {
              id: "FrostaliaPerformance"
            }
          ],
          right: [
            {
              id: "PowerProfile"
            }
          ]
        }
      }
    };
    var target = JSON.parse(JSON.stringify(saved));
    verify(migration.migrate(target, logger, saved));
    compare(target.bar.widgets.left, [
              {
                id: "Clock"
              }
            ]);
    compare(target.bar.screenOverrides[0].widgets.center, []);
    compare(target.controlCenter.shortcuts.left, [
              {
                id: "Network"
              }
            ]);
    compare(target.controlCenter.shortcuts.right, saved.controlCenter.shortcuts.right);
  }
}
