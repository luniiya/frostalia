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

  function test_panel_opacity_data() {
    return [
          {
            tag: "panel overrides",
            open: true,
            closing: false,
            panel: 0.55,
            expected: 0.55
          },
          {
            tag: "panel can turn it off",
            open: true,
            closing: false,
            panel: 0,
            expected: 0
          },
          {
            tag: "negative uses configured",
            open: true,
            closing: false,
            panel: -1,
            expected: 0.2
          },
          {
            tag: "missing uses configured",
            open: true,
            closing: false,
            panel: undefined,
            expected: 0.2
          },
          {
            tag: "closing ignores panel",
            open: true,
            closing: true,
            panel: 0.55,
            expected: 0
          }
        ];
  }

  function test_panel_opacity(data) {
    compare(PanelDimmer.opacity(data.open, data.closing, 0.2, data.panel), data.expected);
  }

  function test_screen_blur_data() {
    return [
          {
            tag: "asked and open",
            open: true,
            closing: false,
            wanted: true,
            expected: true
          },
          {
            tag: "closing",
            open: true,
            closing: true,
            wanted: true,
            expected: false
          },
          {
            tag: "not asked",
            open: true,
            closing: false,
            wanted: false,
            expected: false
          },
          {
            tag: "missing",
            open: true,
            closing: false,
            wanted: undefined,
            expected: false
          },
          {
            tag: "closed",
            open: false,
            closing: false,
            wanted: true,
            expected: false
          }
        ];
  }

  function test_screen_blur(data) {
    compare(PanelDimmer.screenBlur(data.open, data.closing, data.wanted), data.expected);
  }
}
