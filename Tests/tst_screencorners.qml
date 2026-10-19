import QtQuick
import QtTest
import "../Helpers/ScreenCorners.js" as ScreenCorners
import "../Helpers/UiStyles.js" as UiStyles

TestCase {
  name: "ScreenCorners"

  function test_radius_data() {
    return [
          {
            tag: "off",
            ratio: 0,
            expected: 0
          },
          {
            tag: "half",
            ratio: 0.5,
            expected: 10
          },
          {
            tag: "default",
            ratio: 1,
            expected: 20
          },
          {
            tag: "max",
            ratio: 2,
            expected: 40
          },
          {
            tag: "rounded",
            ratio: 1.33,
            expected: 27
          },
          {
            tag: "negative",
            ratio: -1,
            expected: 0
          },
          {
            tag: "invalid",
            ratio: NaN,
            expected: 20
          }
        ];
  }

  function test_radius(data) {
    compare(ScreenCorners.radius(data.ratio), data.expected);
  }

  // Regression: Material used to supply its own 28 px base, so switching styles resized the corners.
  function test_radiusIsNotAStyleToken() {
    UiStyles.choices().forEach(choice => compare(UiStyles.tokens(choice.key).screenRadius, undefined, choice.key));
  }
}
