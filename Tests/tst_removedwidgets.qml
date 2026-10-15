import QtQuick
import QtTest
import "../Helpers/RemovedWidgets.js" as RemovedWidgets

TestCase {
  name: "RemovedWidgets"

  function test_withoutWidgets() {
    var list = [
          {
            "id": "Network"
          },
          {
            "id": "WallpaperSelector"
          },
          {
            "id": "Bluetooth"
          }
        ];
    compare(RemovedWidgets.withoutWidgets(list, ["WallpaperSelector"]), [
              {
                "id": "Network"
              },
              {
                "id": "Bluetooth"
              }
            ]);
    compare(list.length, 3, "input is not mutated");
  }

  function test_unchangedIsIdentical() {
    var list = [
          {
            "id": "Network"
          }
        ];
    verify(RemovedWidgets.withoutWidgets(list, ["WallpaperSelector"]) === list);
    verify(RemovedWidgets.withoutWidgets(undefined, ["WallpaperSelector"]) === undefined);
  }

  function test_sections() {
    var sections = {
      "left": [
        {
          "id": "WallpaperSelector"
        }
      ],
      "center": [],
      "right": [
        {
          "id": "Clock"
        }
      ]
    };
    var out = RemovedWidgets.withoutWidgetsInSections(sections, ["WallpaperSelector"]);
    compare(out.left, []);
    verify(out.right === sections.right);
    var clean = {
      "left": [
        {
          "id": "Clock"
        }
      ]
    };
    verify(RemovedWidgets.withoutWidgetsInSections(clean, ["WallpaperSelector"]) === clean);
  }
}
