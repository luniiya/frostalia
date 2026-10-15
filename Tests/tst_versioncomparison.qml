import QtQuick
import QtTest
import "../Helpers/VersionComparison.js" as VersionComparison

TestCase {
  name: "VersionComparison"

  function test_compare_data() {
    return [
          {
            tag: "identical",
            a: "v4.7.8",
            b: "v4.7.8",
            expected: 0
          },
          {
            tag: "prefix",
            a: "v4.7.8",
            b: "4.7.8",
            expected: 0
          },
          {
            tag: "development suffix",
            a: "v4.7.8-git",
            b: "v4.7.8",
            expected: 0
          },
          {
            tag: "major",
            a: "v5.0.0",
            b: "v4.7.8",
            expected: 1
          },
          {
            tag: "numeric minor",
            a: "v4.10.0",
            b: "v4.9.9",
            expected: 1
          },
          {
            tag: "patch",
            a: "v4.7.7",
            b: "v4.7.8",
            expected: -1
          },
          {
            tag: "missing patch",
            a: "v4.7",
            b: "v4.7.0",
            expected: 0
          },
          {
            tag: "empty",
            a: "",
            b: "",
            expected: 0
          },
          {
            tag: "unknown installed version",
            a: "v1.0.0",
            b: "",
            expected: 1
          }
        ];
  }

  function test_compare(data) {
    compare(VersionComparison.compareVersions(data.a, data.b), data.expected);
  }
}
