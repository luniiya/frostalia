import QtQuick
import QtTest
import "../Helpers/WorkspaceGeometry.js" as Geometry

TestCase {
  name: "WorkspaceGeometry"

  function test_equalPadding_data() {
    return [
          {
            tag: "small dots",
            capsule: 29,
            pill: 15
          },
          {
            tag: "large dots",
            capsule: 29,
            pill: 23
          },
          {
            tag: "full size",
            capsule: 29,
            pill: 29
          },
          {
            tag: "scaled capsule",
            capsule: 38,
            pill: 27
          }
        ];
  }

  function test_equalPadding(data) {
    var padding = Geometry.capsulePadding(data.capsule, data.pill);
    compare(padding, (data.capsule - data.pill) / 2);
    // A horizontal row and vertical column use the same length calculation.
    ["horizontal", "vertical"].forEach(function (orientation) {
      // Include both odd and even workspace counts: rounding the total to odd
      // used to leave an extra pixel at one end of even-length rows.
      [1, 2, 3, 10].forEach(function (count) {
        var contents = data.pill * count + Math.max(0, count - 1) * 4;
        var length = contents + padding * 2;
        compare(length - padding - contents, padding, orientation + " end padding");
        compare(data.capsule - data.pill, padding * 2, orientation + " cross-axis padding");
      });
    });
  }

  function test_oversizedPillDoesNotProduceNegativePadding() {
    compare(Geometry.capsulePadding(29, 31), 0);
  }
}
