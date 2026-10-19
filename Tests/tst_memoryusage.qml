import QtQuick
import QtTest
import "../Helpers/MemoryUsage.js" as MemoryUsage

TestCase {
  name: "MemoryUsage"

  function test_label_data() {
    return [
          {
            tag: "small",
            used: 7.84,
            total: 15.5,
            expected: "7.8/16G"
          },
          {
            tag: "large",
            used: 12.4,
            total: 31.2,
            expected: "12/31G"
          },
          {
            tag: "unknown total",
            used: 3.21,
            total: 0,
            expected: "3.2G"
          },
          {
            tag: "invalid used",
            used: NaN,
            total: 16,
            expected: "0/16G"
          }
        ];
  }

  function test_label(data) {
    compare(MemoryUsage.label(data.used, data.total), data.expected);
  }
}
