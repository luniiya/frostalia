import QtQuick
import QtTest
import "../Helpers/KeycapStyle.js" as KeycapStyle
import "../Helpers/UiStyles.js" as UiStyles

TestCase {
  name: "KeycapStyle"

  function test_sink_data() {
    return [
          {
            tag: "rest",
            down: false,
            hovered: false,
            expected: 0
          },
          {
            tag: "hover lifts",
            down: false,
            hovered: true,
            expected: -1
          },
          {
            tag: "press sinks to the pressed depth",
            down: true,
            hovered: false,
            expected: 2
          },
          {
            tag: "press wins over hover",
            down: true,
            hovered: true,
            expected: 2
          }
        ];
  }

  function test_sink(data) {
    compare(KeycapStyle.sink(3, 1, 1, data.down, data.hovered), data.expected);
  }

  function test_sinkEdgeCases() {
    // A flat key never moves.
    compare(KeycapStyle.sink(0, 1, 1, true, true), 0);
    // The face never sinks below its shadow.
    compare(KeycapStyle.sink(2, 5, 1, true, false), 0);
    compare(KeycapStyle.sink(2, -1, 1, true, false), 2);
    compare(KeycapStyle.sink(undefined, 1, 1, true, false), 0);
    compare(KeycapStyle.shadowOffset(3, 2), 1);
    compare(KeycapStyle.shadowOffset(3, -1), 4);
    compare(KeycapStyle.shadowOffset(3, 5), 0);
  }

  function test_barDepth_data() {
    return [
          {
            tag: "default density",
            bar: 31,
            capsule: 25,
            preferred: 2,
            expected: 2
          },
          {
            tag: "mini density has 1px each side",
            bar: 21,
            capsule: 19,
            preferred: 3,
            expected: 2
          },
          {
            tag: "no slack still keeps one pixel",
            bar: 25,
            capsule: 25,
            preferred: 3,
            expected: 1
          },
          {
            tag: "flat preference",
            bar: 31,
            capsule: 25,
            preferred: 0,
            expected: 0
          }
        ];
  }

  function test_barDepth(data) {
    compare(KeycapStyle.barDepth(data.bar, data.capsule, data.preferred), data.expected);
  }

  function test_inkIsDarkerThanEveryFill() {
    const surfaces = [
            {
              r: 0.13,
              g: 0.14,
              b: 0.22,
              a: 1
            },
            {
              r: 0.98,
              g: 0.96,
              b: 0.92,
              a: 1
            }
          ];
    for (const surface of surfaces) {
      const ink = KeycapStyle.ink(surface);
      verify(KeycapStyle.luminance(ink) < KeycapStyle.luminance(surface));
      compare(ink.a, 1);
    }
    const translucent = KeycapStyle.ink({
                                          r: 1,
                                          g: 1,
                                          b: 1,
                                          a: 0.2
                                        });
    compare(translucent.a, 1);
  }

  function test_readableOn() {
    const ink = {
      r: 0.05,
      g: 0.05,
      b: 0.08,
      a: 1
    };
    const cream = {
      r: 1,
      g: 0.95,
      b: 0.86,
      a: 1
    };
    compare(KeycapStyle.readableOn({
                                     r: 0.95,
                                     g: 0.9,
                                     b: 0.6,
                                     a: 1
                                   }, ink, cream), ink);
    compare(KeycapStyle.readableOn({
                                     r: 0.15,
                                     g: 0.1,
                                     b: 0.3,
                                     a: 1
                                   }, ink, cream), cream);
    verify(KeycapStyle.contrast(ink, cream) > 7);
  }

  function test_ringLeansToCream() {
    const fill = {
      r: 0,
      g: 0,
      b: 0,
      a: 1
    };
    const cream = {
      r: 1,
      g: 1,
      b: 1,
      a: 1
    };
    const ring = KeycapStyle.ring(fill, cream);
    fuzzyCompare(ring.r, 0.75, 0.0001);
    compare(ring.a, 1);
    compare(KeycapStyle.mix(fill, cream, 2).r, 1);
    compare(KeycapStyle.mix(fill, cream, -1).r, 0);
  }

  function test_tiltIsStableBoundedAndNeverFlat() {
    for (const seed of ["Network", "Bluetooth", "NotificationHistory", "", "x"]) {
      const value = KeycapStyle.tilt(seed, 4);
      compare(KeycapStyle.tilt(seed, 4), value, seed);
      verify(Math.abs(value) <= 4, seed);
      verify(value !== 0, seed);
    }
    compare(KeycapStyle.tilt("Network", 0), 0);
    verify(KeycapStyle.tilt("Network", 4) !== KeycapStyle.tilt("Bluetooth", 4));
  }

  function test_levelSegments_data() {
    return [
          {
            tag: "zero",
            level: 0,
            expected: 0
          },
          {
            tag: "tiny lights one",
            level: 0.01,
            expected: 1
          },
          {
            tag: "exact fifth",
            level: 0.2,
            expected: 1
          },
          {
            tag: "half",
            level: 0.5,
            expected: 3
          },
          {
            tag: "full",
            level: 1,
            expected: 5
          },
          {
            tag: "overdrive clamps",
            level: 1.5,
            expected: 5
          },
          {
            tag: "nan",
            level: NaN,
            expected: 0
          },
          {
            tag: "negative",
            level: -0.5,
            expected: 0
          }
        ];
  }

  function test_levelSegments(data) {
    compare(KeycapStyle.levelSegments(data.level, 5), data.expected);
  }

  function test_countLabel() {
    compare(KeycapStyle.countLabel(0), "");
    compare(KeycapStyle.countLabel(-3), "");
    compare(KeycapStyle.countLabel(1), "1");
    compare(KeycapStyle.countLabel(9), "9");
    compare(KeycapStyle.countLabel(10), "9+");
    compare(KeycapStyle.countLabel(150, 99), "99+");
    compare(KeycapStyle.countLabel(2.7), "2");
  }

  function test_flipSegments_data() {
    return [
          {
            tag: "time",
            text: "14:05",
            expected: [["14", true], [":", false], ["05", true]]
          },
          {
            tag: "weekday and time",
            text: "Mon 14:05",
            expected: [["Mon", true], [" ", false], ["14", true], [":", false], ["05", true]]
          },
          {
            tag: "twelve hour",
            text: "2:05 PM",
            expected: [["2", true], [":", false], ["05", true], [" ", false], ["PM", true]]
          },
          {
            tag: "accented month",
            text: "févr.",
            expected: [["févr", true], [".", false]]
          },
          {
            tag: "empty",
            text: "",
            expected: []
          },
          {
            tag: "undefined",
            text: undefined,
            expected: []
          }
        ];
  }

  function test_flipSegments(data) {
    compare(KeycapStyle.flipSegments(data.text).map(s => [s.text, s.tile]), data.expected);
  }

  function test_workspaceKey() {
    compare(KeycapStyle.workspaceKey(true, true, true).kind, "focused");
    compare(KeycapStyle.workspaceKey(false, true, true).kind, "urgent");
    compare(KeycapStyle.workspaceKey(false, false, true).kind, "occupied");
    const empty = KeycapStyle.workspaceKey(false, false, false);
    compare(empty.kind, "empty");
    verify(empty.hollow);
    compare(empty.depthScale, 0);
    verify(KeycapStyle.workspaceKey(false, false, true).depthScale < KeycapStyle.workspaceKey(true, false, false).depthScale);
  }

  function test_profileDot() {
    compare(KeycapStyle.profileDot("power-saver"), 0);
    compare(KeycapStyle.profileDot("balanced"), 1);
    compare(KeycapStyle.profileDot("performance"), 2);
    compare(KeycapStyle.profileDot(undefined), 1);
  }

  // Paths are SVG: they must start with a move, close, and stay inside the box.
  function checkPath(path, w, h) {
    verify(path.indexOf("M ") === 0, path);
    verify(path.trim().endsWith("Z"), path);
    verify(path.indexOf("NaN") === -1, path);
    const numbers = path.replace(/[A-Z]/g, " ").trim().split(/\s+/).map(Number);
    for (const n of numbers)
      verify(isFinite(n), path);
    // Coordinates (all but arc radii and flags) stay within the box.
    const coords = path.match(/[ML] (-?[\d.]+) (-?[\d.]+)/g) || [];
    for (const c of coords) {
      const parts = c.split(" ");
      const x = Number(parts[1]);
      const y = Number(parts[2]);
      verify(x >= -0.01 && x <= w + 0.01 && y >= -0.01 && y <= h + 0.01, c + " in " + path);
    }
  }

  function test_pathsAreClosedAndBounded_data() {
    return [
          {
            tag: "wide",
            w: 120,
            h: 25
          },
          {
            tag: "square",
            w: 25,
            h: 25
          },
          {
            tag: "tall",
            w: 25,
            h: 80
          },
          {
            tag: "tiny",
            w: 4,
            h: 3
          }
        ];
  }

  function test_pathsAreClosedAndBounded(data) {
    checkPath(KeycapStyle.ticketPath(data.w, data.h, 6, data.h, 4), data.w, data.h);
    checkPath(KeycapStyle.tagPath(data.w, data.h, 6, data.h * 0.28), data.w, data.h);
    checkPath(KeycapStyle.tapePath(data.w, data.h, data.h * 0.28), data.w, data.h);
    checkPath(KeycapStyle.receiptPath(data.w, data.h, 6, 3), data.w, data.h);
    checkPath(KeycapStyle.stampPath(data.w, data.h, 2), data.w, data.h);
  }

  function test_ticketNotchesBothEdges() {
    const path = KeycapStyle.ticketPath(100, 24, 6, 24, 4);
    // Two notch arcs (sweep 0) plus four rounded corners (sweep 1)
    compare((path.match(/A 4 4 0 0 0/g) || []).length, 2);
    compare((path.match(/A 6 6 0 0 1/g) || []).length, 4);
    // No notch, no notch arcs
    compare((KeycapStyle.ticketPath(100, 24, 6, 24, 0).match(/0 0 0 /g) || []).length, 0);
  }

  function test_receiptHasTeeth() {
    const path = KeycapStyle.receiptPath(60, 24, 4, 3);
    verify((path.match(/L [\d.]+ 21 /g) || []).length >= 5);
  }

  // ---- registry ----

  function test_keycapIsAChoice() {
    const keys = UiStyles.choices().map(c => c.key);
    verify(keys.indexOf("keycap") !== -1);
    compare(UiStyles.resolveId("keycap"), "keycap");
    compare(UiStyles.tokens("keycap").controls.renderer, "keycap");
  }

  function test_keycapTokensAreComplete() {
    const keycap = UiStyles.tokens("keycap");
    const material = UiStyles.tokens("material");
    for (const group of ["fontSizes", "fontWeights", "radii", "inputRadii", "borders", "margins", "animations"]) {
      compare(Object.keys(keycap[group]).sort(), Object.keys(material[group]).sort(), group);
    }
    // Thicker outlines than the other styles
    verify(keycap.borders.S > material.borders.S);
    verify(keycap.keycap.depth > keycap.keycap.pressedDepth);
    verify(keycap.keycap.overshoot > 1);
    for (const key of ["heightRatio", "trackRatio", "cutoutRatio", "trackOpacity", "gradientDarkening"])
      verify(keycap.slider[key] !== undefined, key);
    for (const key of ["sizeRatio", "widthRatio", "heightRatio", "handleRatio", "handleInset"])
      verify(keycap.toggle[key] !== undefined, key);
  }

  function test_keycapGeometryIsFinite() {
    const slider = UiStyles.sliderGeometry("keycap", 33, 0.7, 1);
    for (const key of ["knobDiameter", "handleHeight", "handleWidth", "trackHeight", "gap", "cutoutExtra"])
      verify(Number.isFinite(slider[key]), key);
    const toggle = UiStyles.toggleGeometry("keycap", 26, true, false);
    verify(toggle.x + toggle.handle <= toggle.width);
    verify(toggle.handle < toggle.height);
  }

  // Keycap is a skin over the Material layouts: same panel views and panel shapes, no glass
  function test_keycapDrawsOnTheMaterialLayouts() {
    for (const surface of ["controlCenter", "mediaCard", "mediaPlayer", "osd", "notificationContent", "kdeConnectHome"])
      compare(UiStyles.view("keycap", surface), UiStyles.view("material", surface), surface);
    compare(UiStyles.glass("keycap", true), null);
    verify(UiStyles.fieldShape("keycap", true) !== null);
    verify(UiStyles.expandableShape("keycap", true) !== null);
    verify(UiStyles.buttonGroupRadii("keycap", 30, false, true, false) !== null);
    for (const token of ["buttonGroup", "expandable", "field", "weather", "menu"])
      verify(UiStyles.tokens("keycap")[token] !== undefined, token);
  }

  function test_barViewsOnlyForKeycap() {
    compare(UiStyles.barView("keycap", "Clock"), "Modules/Bar/Widgets/Keycap/ClockFace.qml");
    compare(UiStyles.barView("keycap", "Plate"), "Modules/Bar/Widgets/Keycap/PlateFace.qml");
    compare(UiStyles.barView("keycap", "NoSuchWidget"), "");
    compare(UiStyles.barView("keycap", ""), "");
    compare(UiStyles.barView("keycap", "toString"), "");
    compare(UiStyles.barView("material", "Clock"), "");
    compare(UiStyles.barView("caelestia", "Clock"), "");
    compare(UiStyles.barView("unknown", "Clock"), "");
  }

  function test_fontFallbacks_data() {
    return [
          {
            tag: "preferred installed",
            configured: "Google Sans Flex",
            available: ["Google Sans Flex", "Rubik"],
            expected: "Google Sans Flex"
          },
          {
            tag: "older Google Sans",
            configured: "Google Sans Flex",
            available: ["Google Sans", "Rubik"],
            expected: "Google Sans"
          },
          {
            tag: "bundled fallback",
            configured: "Google Sans Flex",
            available: ["Rubik", "Roboto"],
            expected: "Rubik"
          },
          {
            tag: "nothing known still uses the last fallback",
            configured: "Google Sans Flex",
            available: [],
            expected: "Rubik"
          },
          {
            tag: "empty setting uses the preset",
            configured: "",
            available: ["Rubik"],
            expected: "Rubik"
          },
          {
            tag: "a chosen font is kept even if missing",
            configured: "Comic Neue",
            available: ["Rubik"],
            expected: "Comic Neue"
          },
          {
            tag: "no list keeps the preset",
            configured: "Google Sans Flex",
            available: null,
            expected: "Google Sans Flex"
          }
        ];
  }

  function test_fontFallbacks(data) {
    compare(UiStyles.fontFamily("keycap", data.configured, false, "System", data.available), data.expected);
  }

  function test_fontFallbacksLeaveOtherStylesAlone() {
    compare(UiStyles.fontFamily("material", "", false, "System", []), "Roboto");
    compare(UiStyles.fontFamily("caelestia", "Missing", false, "System", []), "Missing");
    compare(UiStyles.fontFamily("keycap", "", true, "System", []), "monospace");
  }
}
