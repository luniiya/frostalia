import QtQuick
import QtTest
import "../Helpers/SessionMenuLayout.js" as SessionMenuLayout

TestCase {
  name: "SessionMenuLayout"

  function test_geometry_data() {
    return [
          {
            tag: "desktop grid",
            count: 7,
            mode: "grid",
            width: 1920,
            scale: 1,
            columns: 3,
            rows: 3
          },
          {
            tag: "desktop row",
            count: 7,
            mode: "single-row",
            width: 1920,
            scale: 1,
            columns: 7,
            rows: 1
          },
          {
            tag: "row wraps",
            count: 7,
            mode: "single-row",
            width: 800,
            scale: 1,
            columns: 4,
            rows: 2
          },
          {
            tag: "scaled row wraps",
            count: 7,
            mode: "single-row",
            width: 1920,
            scale: 2,
            columns: 5,
            rows: 2
          },
          {
            tag: "narrow grid",
            count: 8,
            mode: "grid",
            width: 320,
            scale: 1,
            columns: 1,
            rows: 8
          },
          {
            tag: "empty",
            count: 0,
            mode: "grid",
            width: 800,
            scale: 1,
            columns: 1,
            rows: 0
          },
          {
            tag: "single action",
            count: 1,
            mode: "grid",
            width: 800,
            scale: 1,
            columns: 1,
            rows: 1
          }
        ];
  }

  function test_geometry(data) {
    const result = SessionMenuLayout.geometry(data.count, data.mode, data.width, data.scale);
    compare(result.columns, data.columns);
    compare(result.rows, data.rows);
    verify(result.width <= data.width);
    verify(result.tileWidth > 0);
  }

  function test_navigation_data() {
    return [
          {
            tag: "empty",
            count: 0,
            columns: 1,
            selected: -1,
            direction: "down",
            expected: -1
          },
          {
            tag: "initial forward",
            count: 7,
            columns: 3,
            selected: -1,
            direction: "right",
            expected: 0
          },
          {
            tag: "initial backward",
            count: 7,
            columns: 3,
            selected: -1,
            direction: "left",
            expected: 6
          },
          {
            tag: "initial up",
            count: 7,
            columns: 3,
            selected: -1,
            direction: "up",
            expected: 6
          },
          {
            tag: "wrap row",
            count: 7,
            columns: 3,
            selected: 2,
            direction: "right",
            expected: 0
          },
          {
            tag: "wrap left",
            count: 7,
            columns: 3,
            selected: 3,
            direction: "left",
            expected: 5
          },
          {
            tag: "short final row",
            count: 7,
            columns: 3,
            selected: 5,
            direction: "down",
            expected: 6
          },
          {
            tag: "wrap up clamps",
            count: 7,
            columns: 3,
            selected: 2,
            direction: "up",
            expected: 6
          },
          {
            tag: "wrap down",
            count: 7,
            columns: 3,
            selected: 6,
            direction: "down",
            expected: 0
          },
          {
            tag: "responsive row",
            count: 7,
            columns: 4,
            selected: 3,
            direction: "down",
            expected: 6
          },
          {
            tag: "single action",
            count: 1,
            columns: 1,
            selected: 0,
            direction: "up",
            expected: 0
          }
        ];
  }

  function test_navigation(data) {
    compare(SessionMenuLayout.navigate(data.count, data.columns, data.selected, data.direction), data.expected);
  }

  function test_allSelectionsStayInBounds() {
    for (let count = 1; count <= 8; count++) {
      for (let columns = 1; columns <= count; columns++) {
        for (let selected = -1; selected < count; selected++) {
          for (const direction of ["left", "right", "up", "down"]) {
            const next = SessionMenuLayout.navigate(count, columns, selected, direction);
            verify(next >= 0 && next < count);
          }
        }
      }
    }
  }

  function test_tileState_data() {
    return [
          {
            "tag": "idle",
            "args": [1, -1, "lock", "", false, false],
            "expected": {
              "active": false,
              "pending": false,
              "danger": false
            }
          },
          {
            "tag": "selected",
            "args": [2, 2, "reboot", "", false, false],
            "expected": {
              "active": true,
              "pending": false,
              "danger": false
            }
          },
          {
            "tag": "pending but not selected",
            "args": [0, 3, "shutdown", "shutdown", true, true],
            "expected": {
              "active": true,
              "pending": true,
              "danger": true
            }
          },
          {
            "tag": "stale pending action without a timer",
            "args": [0, -1, "lock", "lock", false, false],
            "expected": {
              "active": false,
              "pending": false,
              "danger": false
            }
          },
          {
            "tag": "nothing selected never matches index -1",
            "args": [-1, -1, "", "", true, false],
            "expected": {
              "active": false,
              "pending": false,
              "danger": false
            }
          }
        ];
  }

  function test_tileState(data) {
    compare(SessionMenuLayout.tileState.apply(null, data.args), data.expected);
  }

  function test_countdownProgress_data() {
    return [
          {
            "tag": "start",
            "remaining": 3000,
            "duration": 3000,
            "expected": 0
          },
          {
            "tag": "half",
            "remaining": 1500,
            "duration": 3000,
            "expected": 0.5
          },
          {
            "tag": "overrun",
            "remaining": -100,
            "duration": 3000,
            "expected": 1
          },
          {
            "tag": "no duration",
            "remaining": 0,
            "duration": 0,
            "expected": 0
          }
        ];
  }

  function test_countdownProgress(data) {
    compare(SessionMenuLayout.countdownProgress(data.remaining, data.duration), data.expected);
  }

  function test_revealY_data() {
    // 3 columns, 100 px tiles, 10 px gap, 150 px viewport
    return [
          {
            "tag": "nothing selected keeps the offset",
            "selected": -1,
            "contentY": 40,
            "expected": 40
          },
          {
            "tag": "first row scrolls to top",
            "selected": 1,
            "contentY": 80,
            "expected": 0
          },
          {
            "tag": "visible row keeps the offset",
            "selected": 4,
            "contentY": 100,
            "expected": 100
          },
          {
            "tag": "row below scrolls down to its bottom",
            "selected": 7,
            "contentY": 0,
            "expected": 170
          }
        ];
  }

  function test_revealY(data) {
    compare(SessionMenuLayout.revealY(data.selected, 3, 100, 10, data.contentY, 150), data.expected);
  }
}
