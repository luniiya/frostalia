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
}
