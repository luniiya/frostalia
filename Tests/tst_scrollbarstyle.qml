import QtQuick
import QtTest
import "../Helpers/ScrollbarStyle.js" as ScrollbarStyle

TestCase {
  name: "ScrollbarStyle"

  function test_opacity_data() {
    return [
          {
            tag: "idle",
            hovered: false,
            pressed: false,
            expected: 0.45
          },
          {
            tag: "hovered",
            hovered: true,
            pressed: false,
            expected: 0.7
          },
          {
            tag: "dragged",
            hovered: true,
            pressed: true,
            expected: 0.9
          },
          {
            tag: "dragged outside",
            hovered: false,
            pressed: true,
            expected: 0.9
          }
        ];
  }

  function test_opacity(data) {
    compare(ScrollbarStyle.opacity(data.hovered, data.pressed), data.expected);
  }
}
