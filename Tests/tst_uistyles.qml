import QtQuick
import QtTest
import "../Helpers/UiStyles.js" as UiStyles

TestCase {
  id: root
  name: "UiStyles"

  // The real style folders (Styles/<id>/Definition.qml)
  readonly property var styles: UiStyles.loadAll(Qt.resolvedUrl("../Styles"), ["material", "keycap"])

  function tokens(id) {
    return UiStyles.definition(styles, id).tokens;
  }

  QtObject {
    id: consumer
    property string selectedStyle: "keycap"
    readonly property var tokens: root.tokens(selectedStyle)
    readonly property var slider: UiStyles.sliderGeometry(tokens, tokens.baseWidgetSize, tokens.slider.heightRatio, 1)
  }

  function test_resolveId_data() {
    return [
          {
            tag: "current",
            value: "keycap"
          },
          {
            tag: "missing",
            value: undefined
          },
          {
            tag: "empty",
            value: ""
          },
          {
            tag: "unknown future style",
            value: "liquid-glass"
          },
          {
            tag: "null",
            value: null
          },
          {
            tag: "prototype name",
            value: "toString"
          },
          {
            tag: "prototype object",
            value: "__proto__"
          }
        ];
  }

  function test_resolveId(data) {
    const expected = data.value === "keycap" ? "keycap" : "material";
    compare(UiStyles.resolveId(styles, data.value), expected);
    compare(tokens(data.value), tokens(expected));
  }

  // Regression: loading a definition from the .pragma library failed, so the shell had no styles
  function test_loadAllReadsTheStyleFolders() {
    compare(Object.keys(styles).sort(), ["keycap", "material"]);
    compare(styles.material.labelKey, "options.ui-style.material");
    verify(styles.keycap.barViews.Plate.length > 0);
    ignoreWarning(/has no usable Definition\.qml/);
    compare(Object.keys(UiStyles.loadAll(Qt.resolvedUrl("../Styles"), ["material", "missing"])), ["material"]);
  }

  function test_choices() {
    compare(UiStyles.choices(styles), [
              {
                key: "material",
                labelKey: "options.ui-style.material"
              },
              {
                key: "keycap",
                labelKey: "options.ui-style.keycap"
              }
            ]);
    // A caller changing a menu model must not change the registry.
    const choices = UiStyles.choices(styles);
    choices[0].key = "changed";
    compare(UiStyles.choices(styles)[0].key, "material");
  }

  function test_sliderGeometry_data() {
    return [
          {
            tag: "default",
            scale: 1,
            ratio: 0.7,
            knob: 24,
            track: 10,
            cutout: 4
          },
          {
            tag: "small UI",
            scale: 0.8,
            ratio: 0.7,
            knob: 18,
            track: 6,
            cutout: 2
          },
          {
            tag: "large UI",
            scale: 1.2,
            ratio: 0.7,
            knob: 28,
            track: 14,
            cutout: 4
          },
          {
            tag: "double UI",
            scale: 2,
            ratio: 0.7,
            knob: 46,
            track: 36,
            cutout: 6
          },
          {
            tag: "custom control size",
            scale: 1,
            ratio: 1,
            knob: 34,
            track: 14,
            cutout: 4
          }
        ];
  }

  // Round-knob slider geometry (the non-Material renderers), pinned with fixed tokens
  function test_sliderGeometry(data) {
    const fixture = {
      "slider": {
        "shape": "knob",
        "heightRatio": 0.7,
        "trackRatio": 0.4,
        "cutoutRatio": 0.1
      }
    };
    const geometry = UiStyles.sliderGeometry(fixture, 33, data.ratio, data.scale);
    compare(geometry.knobDiameter, data.knob);
    compare(geometry.trackHeight, data.track);
    compare(geometry.cutoutExtra, data.cutout);
  }

  function test_fontFamily_data() {
    return [
          {
            tag: "saved font",
            family: "FiraCode Nerd Font Mono",
            fixed: false,
            expected: "FiraCode Nerd Font Mono"
          },
          {
            tag: "saved monospace",
            family: "Iosevka",
            fixed: true,
            expected: "Iosevka"
          },
          {
            tag: "Keycap preset font",
            family: "",
            fixed: false,
            expected: "Google Sans Flex"
          },
          {
            tag: "style monospace fallback",
            family: "",
            fixed: true,
            expected: "monospace"
          }
        ];
  }

  function test_fontFamily(data) {
    compare(UiStyles.fontFamily(tokens("keycap"), data.family, data.fixed, "System Font"), data.expected);
  }

  function test_materialStyleSwitchIsReversible() {
    const original = JSON.stringify(tokens("keycap"));
    try {
      compare(UiStyles.resolveId(styles, "material"), "material");
      consumer.selectedStyle = "material";
      compare(consumer.tokens.slider.shape, "split");
      compare(consumer.tokens.radii.M, 24);
      compare(consumer.slider.trackHeight, 16);
      compare(consumer.slider.handleHeight, 44);
      compare(UiStyles.fontFamily(tokens("material"), "", false, "System"), "Roboto");
      compare(UiStyles.fontFamily(tokens("material"), "My Font", false, "System"), "My Font");
      consumer.selectedStyle = "keycap";
      compare(consumer.tokens.slider.shape, "knob");
      compare(consumer.slider.trackHeight, 10);
      compare(JSON.stringify(consumer.tokens), original);
    } finally {
      consumer.selectedStyle = "keycap";
    }
  }

  function test_materialSliderScalesOnce_data() {
    return [
          {
            tag: "small",
            scale: 0.8
          },
          {
            tag: "default",
            scale: 1
          },
          {
            tag: "large",
            scale: 1.5
          },
          {
            tag: "double",
            scale: 2
          }
        ];
  }

  function test_materialSliderScalesOnce(data) {
    const g = UiStyles.sliderGeometry(tokens("material"), 33, 0.7, data.scale);
    compare(g.knobDiameter, Math.round(40 * data.scale));
    compare(g.trackHeight, Math.round(16 * data.scale));
    compare(g.handleHeight, Math.round(44 * data.scale));
    compare(g.handleWidth, 4 * data.scale);
    compare(g.gap, 12 * data.scale);
    const custom = UiStyles.sliderGeometry(tokens("material"), 33, 0.35, data.scale);
    compare(custom.handleHeight, Math.round(22 * data.scale));
  }

  function test_sliderGeometryHasCompleteShapeDuringStyleSwitches() {
    // QML bindings may observe the renderer and dimensions in either order.
    // Both styles must supply finite dimensions throughout a live switch.
    for (const style of ["material", "keycap", "unknown"]) {
      const g = UiStyles.sliderGeometry(tokens(style), 33, 0.7, 1);
      for (const key of ["knobDiameter", "handleHeight", "handleWidth", "pressedHandleWidth", "trackHeight", "gap", "cutoutExtra"]) {
        verify(Number.isFinite(g[key]), style + ":" + key);
      }
    }
  }

  function test_splitTrackBounds_data() {
    const rows = [];
    for (const width of [0, 12, 40, 41, 200]) {
      for (const position of [0, 0.01, 0.5, 0.99, 1]) {
        for (const mirrored of [false, true]) {
          rows.push({
                      tag: width + ":" + position + ":" + mirrored,
                      width: width,
                      position: position,
                      mirrored: mirrored
                    });
        }
      }
    }
    return rows;
  }

  function test_splitTrackBounds(data) {
    const g = UiStyles.splitSliderTrack(data.width, 40, data.position, 12, data.mirrored);
    verify(g.activeWidth >= 0);
    verify(g.inactiveWidth >= 0);
    verify(g.activeX >= g.start);
    verify(g.inactiveX >= g.start);
    verify(g.activeX + g.activeWidth <= g.end + 0.001);
    verify(g.inactiveX + g.inactiveWidth <= g.end + 0.001);
    const reflected = UiStyles.splitSliderTrack(data.width, 40, 1 - data.position, 12, !data.mirrored);
    fuzzyCompare(g.activeWidth, reflected.activeWidth, 0.001);
    fuzzyCompare(g.inactiveWidth, reflected.inactiveWidth, 0.001);
  }

  function test_splitTrackEndpoints() {
    compare(UiStyles.splitSliderTrack(200, 40, 0, 12, false).activeWidth, 0);
    compare(UiStyles.splitSliderTrack(200, 40, 1, 12, false).inactiveWidth, 0);
    const middle = UiStyles.splitSliderTrack(200, 40, 0.5, 12, false);
    compare(middle.activeX + middle.activeWidth, 94);
    compare(middle.inactiveX, 106);
  }

  function test_glass() {
    compare(UiStyles.glass(tokens("material"), true).panelOpacity, 0.85);
    compare(UiStyles.glass(tokens("material"), true).surfaceOpacity, 0.7);
    compare(UiStyles.glass(tokens("material"), false), null);
    compare(UiStyles.glass(tokens("keycap"), true), null);
  }

  function test_glassCustom_data() {
    return [
          {
            tag: "custom",
            custom: {
              panelOpacity: 0.6,
              surfaceOpacity: 0.4
            },
            panel: 0.6,
            surface: 0.4
          },
          {
            tag: "fully clear",
            custom: {
              panelOpacity: 0,
              surfaceOpacity: 0
            },
            panel: 0,
            surface: 0
          },
          {
            tag: "clamped",
            custom: {
              panelOpacity: 1.5,
              surfaceOpacity: -1
            },
            panel: 1,
            surface: 0
          },
          {
            tag: "missing uses style",
            custom: {
              panelOpacity: undefined,
              surfaceOpacity: null
            },
            panel: 0.85,
            surface: 0.7
          },
          {
            tag: "invalid uses style",
            custom: {
              panelOpacity: "abc",
              surfaceOpacity: ""
            },
            panel: 0.85,
            surface: 0.7
          },
          {
            tag: "no custom",
            custom: undefined,
            panel: 0.85,
            surface: 0.7
          }
        ];
  }

  function test_glassCustom(data) {
    const frosted = UiStyles.glass(tokens("material"), true, data.custom);
    compare(frosted.panelOpacity, data.panel);
    compare(frosted.surfaceOpacity, data.surface);
    compare(UiStyles.glass(tokens("material"), false, data.custom), null);
    compare(UiStyles.glass(tokens("keycap"), true, data.custom), null);
  }

  function test_panelOpacity_data() {
    return [
          {
            tag: "material glass",
            style: "material",
            glass: true,
            expected: 0.85
          },
          {
            tag: "material opaque",
            style: "material",
            glass: false,
            expected: 0.9
          },
          {
            tag: "keycap ignores glass",
            style: "keycap",
            glass: true,
            expected: 0.9
          },
          {
            tag: "material custom glass",
            style: "material",
            glass: true,
            custom: {
              panelOpacity: 0.5
            },
            expected: 0.5
          },
          {
            tag: "custom ignored when off",
            style: "material",
            glass: false,
            custom: {
              panelOpacity: 0.5
            },
            expected: 0.9
          }
        ];
  }

  function test_panelOpacity(data) {
    compare(UiStyles.panelOpacity(tokens(data.style), 0.9, data.glass, data.custom), data.expected);
  }

  function test_fieldShape_data() {
    return [
          {
            tag: "idle",
            focused: false,
            radius: 12,
            borderWidth: 0
          },
          {
            tag: "focused",
            focused: true,
            radius: 12,
            borderWidth: 1
          },
          {
            tag: "search idle",
            focused: false,
            cornerRadius: 20,
            radius: 20,
            borderWidth: 0
          },
          {
            tag: "search focused",
            focused: true,
            cornerRadius: 20,
            radius: 20,
            borderWidth: 1
          },
          {
            tag: "square override",
            focused: true,
            cornerRadius: 0,
            radius: 0,
            borderWidth: 1
          }
        ];
  }

  function test_fieldShape(data) {
    const shape = UiStyles.fieldShape(tokens("material"), data.focused, data.cornerRadius);
    compare(shape.radius, data.radius);
    compare(shape.borderWidth, data.borderWidth);
  }

  function test_keycapUsesTheMaterialFieldShape() {
    compare(UiStyles.fieldShape(tokens("keycap"), true).borderWidth, 2);
  }

  function test_weatherTokens() {
    compare(tokens("material").weather.cookieLobes, 9);
    compare(tokens("keycap").weather.cookieLobes, 9);
  }

  function test_menuTokens() {
    compare(tokens("material").menu.radius, 16);
    compare(tokens("keycap").menu.radius, 14);
  }

  function test_expandableShape_data() {
    return [
          {
            tag: "collapsed",
            expanded: false,
            headerBottom: 24
          },
          {
            tag: "expanded",
            expanded: true,
            headerBottom: 4
          }
        ];
  }

  function test_expandableShape(data) {
    const shape = UiStyles.expandableShape(tokens("material"), data.expanded);
    compare(shape.gap, 2);
    compare(shape.headerTop, 24);
    compare(shape.headerBottom, data.headerBottom);
    compare(shape.contentTop, 4);
    compare(shape.contentBottom, 24);
  }

  function test_keycapUsesTheMaterialExpandableShape() {
    compare(UiStyles.expandableShape(tokens("keycap"), true).headerTop, 22);
  }

  function test_buttonGroupRadii_data() {
    return [
          {
            tag: "first unselected",
            checked: false,
            isFirst: true,
            isLast: false,
            left: 16,
            right: 8
          },
          {
            tag: "middle unselected",
            checked: false,
            isFirst: false,
            isLast: false,
            left: 8,
            right: 8
          },
          {
            tag: "last unselected",
            checked: false,
            isFirst: false,
            isLast: true,
            left: 8,
            right: 16
          },
          {
            tag: "middle selected",
            checked: true,
            isFirst: false,
            isLast: false,
            left: 16,
            right: 16
          },
          {
            tag: "single",
            checked: false,
            isFirst: true,
            isLast: true,
            left: 16,
            right: 16
          }
        ];
  }

  function test_buttonGroupRadii(data) {
    const radii = UiStyles.buttonGroupRadii(tokens("material"), 32, data.checked, data.isFirst, data.isLast);
    compare(radii.left, data.left);
    compare(radii.right, data.right);
  }

  function test_buttonGroupRadiiClampsInnerRadius() {
    const radii = UiStyles.buttonGroupRadii(tokens("material"), 10, false, false, false);
    compare(radii.left, 5);
    compare(radii.right, 5);
  }

  function test_keycapUsesTheMaterialButtonGroupRadii() {
    verify(UiStyles.buttonGroupRadii(tokens("keycap"), 32, true, true, true) !== null);
  }

  function test_toggleGeometry_data() {
    return [
          {
            tag: "keycap off",
            style: "keycap",
            checked: false,
            pressed: false,
            width: 46,
            height: 26,
            handle: 18,
            x: 4
          },
          {
            tag: "keycap on",
            style: "keycap",
            checked: true,
            pressed: false,
            width: 46,
            height: 26,
            handle: 18,
            x: 24
          },
          {
            tag: "keycap pressed",
            style: "keycap",
            checked: true,
            pressed: true,
            width: 46,
            height: 26,
            handle: 18,
            x: 24
          },
          {
            tag: "material off",
            style: "material",
            checked: false,
            pressed: false,
            width: 52,
            height: 32,
            handle: 16,
            x: 8
          },
          {
            tag: "material on",
            style: "material",
            checked: true,
            pressed: false,
            width: 52,
            height: 32,
            handle: 24,
            x: 24
          },
          {
            tag: "material off pressed",
            style: "material",
            checked: false,
            pressed: true,
            width: 52,
            height: 32,
            handle: 28,
            x: 2
          },
          {
            tag: "material on pressed",
            style: "material",
            checked: true,
            pressed: true,
            width: 52,
            height: 32,
            handle: 28,
            x: 22
          }
        ];
  }

  function test_toggleGeometry(data) {
    const geometry = UiStyles.toggleGeometry(tokens(data.style), 26, data.checked, data.pressed);
    compare(geometry.width, data.width);
    compare(geometry.height, data.height);
    compare(geometry.handle, data.handle);
    compare(geometry.x, data.x);
    if (data.style === "material") {
      const scaled = UiStyles.toggleGeometry(tokens(data.style), 52, data.checked, data.pressed);
      compare(scaled.width, geometry.width * 2);
      compare(scaled.height, geometry.height * 2);
      compare(scaled.handle, geometry.handle * 2);
      compare(scaled.x, geometry.x * 2);
    }
  }

  function test_switchingStylesUpdatesBindings() {
    // Register a fixture to exercise a second style without shipping unfinished styles.
    const original = JSON.stringify(tokens("keycap"));
    const custom = JSON.parse(original);
    custom.baseWidgetSize = 40;
    custom.slider.trackRatio = 0.25;
    custom.fontFamily = "Style Font";
    custom.radii.M = 2;
    styles.fixture = {
      labelKey: "fixture",
      tokens: custom
    };
    try {
      compare(consumer.tokens.radii.M, 18);
      consumer.selectedStyle = "fixture";
      compare(consumer.tokens.radii.M, 2);
      compare(consumer.slider.knobDiameter, 28);
      compare(consumer.slider.trackHeight, 8);
      compare(UiStyles.fontFamily(tokens("fixture"), "", false, "System Font"), "Style Font");
      compare(UiStyles.fontFamily(tokens("fixture"), "My Font", false, "System Font"), "My Font");
      verify(UiStyles.choices(styles).some(choice => choice.key === "fixture"));
      consumer.selectedStyle = "keycap";
      compare(consumer.tokens.radii.M, 18);
      compare(consumer.slider.knobDiameter, 24);
      compare(JSON.stringify(tokens("keycap")), original);
    } finally {
      consumer.selectedStyle = "keycap";
      delete styles.fixture;
    }
  }
}
