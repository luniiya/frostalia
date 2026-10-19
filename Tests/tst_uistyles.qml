import QtQuick
import QtTest
import "../Helpers/UiStyles.js" as UiStyles

TestCase {
  name: "UiStyles"

  QtObject {
    id: consumer
    property string selectedStyle: "caelestia"
    readonly property var tokens: UiStyles.tokens(selectedStyle)
    readonly property var slider: UiStyles.sliderGeometry(selectedStyle, tokens.baseWidgetSize, tokens.slider.heightRatio, 1)
  }

  function test_resolveId_data() {
    return [
          {
            tag: "current",
            value: "caelestia"
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
    compare(UiStyles.resolveId(data.value), "caelestia");
    compare(UiStyles.tokens(data.value), UiStyles.tokens("caelestia"));
  }

  function test_choices() {
    compare(UiStyles.choices(), [
              {
                key: "caelestia",
                labelKey: "options.ui-style.caelestia"
              },
              {
                key: "material",
                labelKey: "options.ui-style.material"
              }
            ]);
    // A caller changing a menu model must not change the registry.
    const choices = UiStyles.choices();
    choices[0].key = "changed";
    compare(UiStyles.choices()[0].key, "caelestia");
  }

  function test_currentAppearanceIsPreserved() {
    const tokens = UiStyles.tokens("caelestia");
    compare(tokens.fontSizes, {
              XXS: 8,
              XS: 9,
              S: 10,
              M: 11,
              L: 13,
              XL: 16,
              XXL: 18,
              XXXL: 24
            });
    compare(tokens.fontWeights, {
              Regular: 400,
              Medium: 500,
              SemiBold: 600,
              Bold: 700
            });
    compare(tokens.radii, {
              XXXS: 3,
              XXS: 4,
              XS: 8,
              S: 12,
              M: 16,
              L: 20
            });
    compare(tokens.inputRadii, tokens.radii);
    compare(tokens.margins, {
              XXXS: 1,
              XXS: 2,
              XS: 4,
              S: 6,
              M: 9,
              L: 13,
              XL: 18
            });
    compare(tokens.borders, {
              S: 1,
              M: 2,
              L: 3
            });
    compare(tokens.animations, {
              Faster: 75,
              Fast: 150,
              Normal: 300,
              Slow: 450,
              Slowest: 750
            });
    compare(tokens.baseWidgetSize, 33);
    compare(tokens.sliderWidth, 200);
    compare(tokens.slider, {
              heightRatio: 0.7,
              trackRatio: 0.4,
              cutoutRatio: 0.1,
              trackOpacity: 0.5,
              gradientDarkening: 1.2
            });
    compare(tokens.toggle, {
              sizeRatio: 0.8,
              widthRatio: 0.85,
              heightRatio: 0.5,
              handleRatio: 0.4,
              handleInset: 3
            });
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

  function test_sliderGeometry(data) {
    const geometry = UiStyles.sliderGeometry("caelestia", 33, data.ratio, data.scale);
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
            tag: "Caelestia preset font",
            family: "",
            fixed: false,
            expected: "Rubik"
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
    compare(UiStyles.fontFamily("caelestia", data.family, data.fixed, "System Font"), data.expected);
  }

  function test_materialStyleSwitchIsReversible() {
    const original = JSON.stringify(UiStyles.tokens("caelestia"));
    try {
      compare(UiStyles.resolveId("material"), "material");
      consumer.selectedStyle = "material";
      compare(consumer.tokens.controls.renderer, "material");
      compare(consumer.tokens.radii.M, 24);
      compare(consumer.slider.trackHeight, 16);
      compare(consumer.slider.handleHeight, 44);
      compare(UiStyles.fontFamily("material", "", false, "System"), "Roboto");
      compare(UiStyles.fontFamily("material", "My Font", false, "System"), "My Font");
      consumer.selectedStyle = "caelestia";
      compare(consumer.tokens.controls.renderer, "caelestia");
      compare(consumer.slider.trackHeight, 10);
      compare(JSON.stringify(consumer.tokens), original);
    } finally {
      consumer.selectedStyle = "caelestia";
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
    const g = UiStyles.sliderGeometry("material", 33, 0.7, data.scale);
    compare(g.knobDiameter, Math.round(40 * data.scale));
    compare(g.trackHeight, Math.round(16 * data.scale));
    compare(g.handleHeight, Math.round(44 * data.scale));
    compare(g.handleWidth, 4 * data.scale);
    compare(g.gap, 12 * data.scale);
    const custom = UiStyles.sliderGeometry("material", 33, 0.35, data.scale);
    compare(custom.handleHeight, Math.round(22 * data.scale));
  }

  function test_sliderGeometryHasCompleteShapeDuringStyleSwitches() {
    // QML bindings may observe the renderer and dimensions in either order.
    // Both styles must supply finite dimensions throughout a live switch.
    for (const style of ["caelestia", "material", "unknown"]) {
      const g = UiStyles.sliderGeometry(style, 33, 0.7, 1);
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

  function test_toggleGeometry_data() {
    return [
          {
            tag: "legacy off",
            style: "caelestia",
            checked: false,
            pressed: false,
            width: 44,
            height: 26,
            handle: 20,
            x: 3
          },
          {
            tag: "legacy on",
            style: "caelestia",
            checked: true,
            pressed: false,
            width: 44,
            height: 26,
            handle: 20,
            x: 21
          },
          {
            tag: "legacy pressed",
            style: "caelestia",
            checked: true,
            pressed: true,
            width: 44,
            height: 26,
            handle: 20,
            x: 21
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
    const geometry = UiStyles.toggleGeometry(data.style, 26, data.checked, data.pressed);
    compare(geometry.width, data.width);
    compare(geometry.height, data.height);
    compare(geometry.handle, data.handle);
    compare(geometry.x, data.x);
    if (data.style === "material") {
      const scaled = UiStyles.toggleGeometry(data.style, 52, data.checked, data.pressed);
      compare(scaled.width, geometry.width * 2);
      compare(scaled.height, geometry.height * 2);
      compare(scaled.handle, geometry.handle * 2);
      compare(scaled.x, geometry.x * 2);
    }
  }

  function test_switchingStylesUpdatesBindings() {
    // Register a fixture to exercise a second style without shipping unfinished styles.
    const original = JSON.stringify(UiStyles.tokens("caelestia"));
    const custom = JSON.parse(original);
    custom.baseWidgetSize = 40;
    custom.slider.trackRatio = 0.25;
    custom.fontFamily = "Style Font";
    custom.radii.M = 2;
    UiStyles.definitions.fixture = {
      labelKey: "fixture",
      tokens: custom
    };
    try {
      compare(consumer.tokens.radii.M, 16);
      consumer.selectedStyle = "fixture";
      compare(consumer.tokens.radii.M, 2);
      compare(consumer.slider.knobDiameter, 28);
      compare(consumer.slider.trackHeight, 8);
      compare(UiStyles.fontFamily("fixture", "", false, "System Font"), "Style Font");
      compare(UiStyles.fontFamily("fixture", "My Font", false, "System Font"), "My Font");
      verify(UiStyles.choices().some(choice => choice.key === "fixture"));
      consumer.selectedStyle = "caelestia";
      compare(consumer.tokens.radii.M, 16);
      compare(consumer.slider.knobDiameter, 24);
      compare(JSON.stringify(UiStyles.tokens("caelestia")), original);
    } finally {
      consumer.selectedStyle = "caelestia";
      delete UiStyles.definitions.fixture;
    }
  }
}
