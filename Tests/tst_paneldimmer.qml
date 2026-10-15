import QtQuick
import QtTest
import "../Helpers/PanelDimmer.js" as PanelDimmer

TestCase {
  name: "PanelDimmer"

  function test_opacity_data() {
    return [
          {
            tag: "closed",
            open: false,
            closing: false,
            configured: 0.2,
            expected: 0
          },
          {
            tag: "open",
            open: true,
            closing: false,
            configured: 0.2,
            expected: 0.2
          },
          {
            tag: "closing",
            open: true,
            closing: true,
            configured: 0.2,
            expected: 0
          },
          {
            tag: "disabled",
            open: true,
            closing: false,
            configured: 0,
            expected: 0
          },
          {
            tag: "clamped",
            open: true,
            closing: false,
            configured: 2,
            expected: 1
          }
        ];
  }

  function test_opacity(data) {
    compare(PanelDimmer.opacity(data.open, data.closing, data.configured), data.expected);
  }
}
