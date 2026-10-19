import QtQuick
import QtTest
import "../Helpers/DesktopWidgetEdit.js" as WidgetEdit

TestCase {
  name: "DesktopWidgetEdit"

  function test_scale_data() {
    return [
          {
            tag: "snap down",
            value: 1.03,
            precise: false,
            base: 240,
            grid: 0,
            expected: 1
          },
          {
            tag: "snap up",
            value: 1.08,
            precise: false,
            base: 240,
            grid: 0,
            expected: 1.1
          },
          {
            tag: "default size",
            value: 0.98,
            precise: false,
            base: 240,
            grid: 0,
            expected: 1
          },
          {
            tag: "precise shift",
            value: 1.037,
            precise: true,
            base: 240,
            grid: 0,
            expected: 1.037
          },
          {
            tag: "minimum",
            value: 0.1,
            precise: false,
            base: 240,
            grid: 0,
            expected: 0.5
          },
          {
            tag: "maximum",
            value: 6,
            precise: false,
            base: 240,
            grid: 0,
            expected: 5
          },
          {
            tag: "grid scaling",
            value: 1.08,
            precise: false,
            base: 240,
            grid: 30,
            expected: 1.125
          },
          {
            tag: "shift bypasses grid",
            value: 1.08,
            precise: true,
            base: 240,
            grid: 30,
            expected: 1.08
          },
          {
            tag: "grid unavailable",
            value: 1.08,
            precise: false,
            base: 0,
            grid: 30,
            expected: 1.1
          },
          {
            tag: "invalid",
            value: NaN,
            precise: false,
            base: 240,
            grid: 0,
            expected: 1
          }
        ];
  }

  function test_scale(data) {
    fuzzyCompare(WidgetEdit.snappedScale(data.value, 0.5, 5, data.precise, data.base, data.grid), data.expected, 0.000001);
  }

  function test_resizeAxis_data() {
    return [
          {
            tag: "right edge",
            leading: false,
            delta: 37,
            step: 10,
            precise: false,
            length: 280
          },
          {
            tag: "left edge",
            leading: true,
            delta: -37,
            step: 10,
            precise: false,
            length: 280
          },
          {
            tag: "bottom shrink",
            leading: false,
            delta: -37,
            step: 10,
            precise: false,
            length: 200
          },
          {
            tag: "top shrink",
            leading: true,
            delta: 37,
            step: 10,
            precise: false,
            length: 200
          },
          {
            tag: "grid",
            leading: false,
            delta: 37,
            step: 30,
            precise: false,
            length: 270
          },
          {
            tag: "shift",
            leading: true,
            delta: -37,
            step: 30,
            precise: true,
            length: 277
          },
          {
            tag: "minimum",
            leading: true,
            delta: 500,
            step: 10,
            precise: false,
            length: 96
          },
          {
            tag: "maximum",
            leading: false,
            delta: 5000,
            step: 10,
            precise: false,
            length: 1200
          },
          {
            tag: "click without drag",
            leading: true,
            delta: 0,
            step: 50,
            precise: false,
            length: 240
          }
        ];
  }

  function test_resizeAxis(data) {
    const result = WidgetEdit.resizedAxis(100, 240, data.delta, data.leading, 96, 1200, data.step, data.precise);
    compare(result.length, data.length);
    if (data.leading)
      compare(result.start + result.length, 340);
    else
      compare(result.start, 100);
  }

  function test_multiplierLabel() {
    compare(WidgetEdit.scaleText(1), "1.00");
    compare(WidgetEdit.scaleText(1.5), "1.50");
    compare(WidgetEdit.scaleText(0.5), "0.50");
  }

  function test_feedbackRemainsOnScreen_data() {
    return [
          {
            tag: "center",
            x: 400,
            y: 400
          },
          {
            tag: "top",
            x: 400,
            y: 0
          },
          {
            tag: "left clipped",
            x: -100,
            y: 100
          },
          {
            tag: "right clipped",
            x: 1800,
            y: 100
          },
          {
            tag: "bottom clipped",
            x: 500,
            y: 1070
          }
        ];
  }

  function test_feedbackRemainsOnScreen(data) {
    const feedback = WidgetEdit.feedbackPosition(data.x, data.y, 240, 120, 180, 32, 1920, 1080, 8);
    verify(data.x + feedback.x >= 8);
    verify(data.x + feedback.x + 180 <= 1912);
    verify(data.y + feedback.y >= 8);
    verify(data.y + feedback.y + 32 <= 1072);
  }
}
