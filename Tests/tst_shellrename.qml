import QtQuick
import QtTest
import "../Helpers/ShellRename.js" as ShellRename

TestCase {
  name: "ShellRename"

  function test_renamesWidgetIds() {
    var widgets = [
          {
            "id": "Network"
          },
          {
            "id": "NoctaliaPerformance",
            "iconColor": "none"
          }
        ];
    compare(ShellRename.renameValue(widgets), [
              {
                "id": "Network"
              },
              {
                "id": "FrostaliaPerformance",
                "iconColor": "none"
              }
            ]);
  }

  function test_renamesBatteryToggleKey() {
    var widgets = [
          {
            "id": "Battery",
            "showNoctaliaPerformance": true,
            "showPowerProfiles": false
          }
        ];
    compare(ShellRename.renameValue(widgets), [
              {
                "id": "Battery",
                "showFrostaliaPerformance": true,
                "showPowerProfiles": false
              }
            ]);
  }

  function test_nestedScreenOverrides() {
    var overrides = [
          {
            "name": "eDP-1",
            "widgets": {
              "left": [
                {
                  "id": "NoctaliaPerformance"
                }
              ]
            }
          }
        ];
    compare(ShellRename.renameValue(overrides)[0].widgets.left[0].id, "FrostaliaPerformance");
  }

  // Unchanged values come back as the same object so the migration can skip writing them
  function test_unchangedIsIdentical() {
    var widgets = [
          {
            "id": "Clock",
            "format": "HH:mm"
          }
        ];
    verify(ShellRename.renameValue(widgets) === widgets);
    verify(ShellRename.renameValue(undefined) === undefined);
  }

  // Only widget ids are renamed, not arbitrary text that happens to match
  function test_onlyIdValuesAreRenamed() {
    var w = {
      "id": "CustomButton",
      "label": "NoctaliaPerformance"
    };
    verify(ShellRename.renameValue(w) === w);
  }

  function test_doesNotMutateInput() {
    var widgets = [
          {
            "id": "NoctaliaPerformance"
          }
        ];
    ShellRename.renameValue(widgets);
    compare(widgets[0].id, "NoctaliaPerformance");
  }
}
