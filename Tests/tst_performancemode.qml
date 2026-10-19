import QtQuick
import QtTest
import "../Commons/Migrations"
import "../Helpers/PerformanceMode.js" as PerformanceMode

TestCase {
  name: "PerformanceMode"

  // Stand-ins for PowerProfile.PowerSaver, Balanced and Performance
  readonly property int powerSaver: 0
  readonly property int balanced: 1
  readonly property int performance: 2

  Migration68 {
    id: migration
  }

  QtObject {
    id: logger
    function i() {}
  }

  function test_enabled_data() {
    return [
          {
            tag: "performance",
            available: true,
            profile: performance,
            expected: true
          },
          {
            tag: "balanced",
            available: true,
            profile: balanced,
            expected: false
          },
          {
            tag: "power saver",
            available: true,
            profile: powerSaver,
            expected: false
          },
          {
            tag: "no power profiles",
            available: false,
            profile: performance,
            expected: false
          }
        ];
  }

  function test_enabled(data) {
    compare(PerformanceMode.enabled(data.available, data.profile, performance), data.expected);
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
