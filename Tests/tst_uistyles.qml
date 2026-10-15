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
    compare(tokens.screenRadius, 20);
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
            tag: "application fallback",
            family: "",
            fixed: false,
            expected: "System Font"
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
