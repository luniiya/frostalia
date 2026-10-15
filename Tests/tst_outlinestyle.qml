import QtQuick
import QtTest
import "../Helpers/OutlineStyle.js" as OutlineStyle

TestCase {
  name: "OutlineStyle"

  function rgba(r, g, b, a) {
    return {
      r: r,
      g: g,
      b: b,
      a: a
    };
  }

  function fuzzyColor(actual, expected) {
    fuzzyCompare(actual.r, expected.r, 1e-9);
    fuzzyCompare(actual.g, expected.g, 1e-9);
    fuzzyCompare(actual.b, expected.b, 1e-9);
    fuzzyCompare(actual.a, expected.a, 1e-9);
  }

  function test_borderWidth_data() {
    return [
          {
            tag: "default",
            setting: 1,
            scale: 1,
            e: 1
          },
          {
            tag: "thick",
            setting: 3,
            scale: 1,
            e: 3
          },
          {
            tag: "scaled",
            setting: 2,
            scale: 1.5,
            e: 3
          },
          {
            tag: "tiny scale keeps 1px",
            setting: 1,
            scale: 0.4,
            e: 1
          },
          {
            tag: "clamped high",
            setting: 50,
            scale: 1,
            e: 6
          },
          {
            tag: "clamped low",
            setting: 0,
            scale: 1,
            e: 1
          },
          {
            tag: "undefined",
            setting: undefined,
            scale: 1,
            e: 1
          },
          {
            tag: "bad scale",
            setting: 2,
            scale: 0,
            e: 2
          }
        ];
  }
  function test_borderWidth(d) {
    compare(OutlineStyle.borderWidth(d.setting, d.scale), d.e);
  }

  // The defaults must keep the previous look: Style.borderS was max(1, round(1 * uiScale))
  function test_defaultWidthMatchesOldBorderS() {
    for (const scale of [0.8, 1, 1.25, 1.5, 2])
      compare(OutlineStyle.borderWidth(1, scale), Math.max(1, Math.round(1 * scale)));
  }

  function test_adjustBrightness() {
    var c = rgba(0.2, 0.4, 0.6, 0.8);
    fuzzyColor(OutlineStyle.adjustBrightness(c, 0), c);
    fuzzyColor(OutlineStyle.adjustBrightness(c, 100), rgba(1, 1, 1, 0.8));
    fuzzyColor(OutlineStyle.adjustBrightness(c, -100), rgba(0, 0, 0, 0.8));
    fuzzyColor(OutlineStyle.adjustBrightness(c, 50), rgba(0.6, 0.7, 0.8, 0.8));
    fuzzyColor(OutlineStyle.adjustBrightness(c, -50), rgba(0.1, 0.2, 0.3, 0.8));
    fuzzyColor(OutlineStyle.adjustBrightness(c, 500), rgba(1, 1, 1, 0.8));
    fuzzyColor(OutlineStyle.adjustBrightness(c, undefined), c);
  }

  function test_outlineColor() {
    var c = rgba(0.2, 0.4, 0.6, 0.8);
    fuzzyColor(OutlineStyle.outlineColor(c, 0, 100), c);
    fuzzyColor(OutlineStyle.outlineColor(c, 0, 50), rgba(0.2, 0.4, 0.6, 0.4));
    fuzzyColor(OutlineStyle.outlineColor(c, 0, 0), rgba(0.2, 0.4, 0.6, 0));
    fuzzyColor(OutlineStyle.outlineColor(c, 0, undefined), c);
    fuzzyColor(OutlineStyle.outlineColor(c, -50, 50), rgba(0.1, 0.2, 0.3, 0.4));
  }
}
