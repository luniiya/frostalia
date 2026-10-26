import QtQuick
import QtTest
import "../Helpers/UiProbe.js" as UiProbe

TestCase {
  name: "UiProbe"

  function test_windowOrigin_data() {
    return [
          {
            tag: "left bar",
            anchors: {
              "top": true,
              "bottom": true,
              "left": true
            },
            margins: {
              "top": 4,
              "left": 8
            },
            expected: {
              "x": 8,
              "y": 4
            }
          },
          {
            tag: "right bar",
            anchors: {
              "top": true,
              "bottom": true,
              "right": true
            },
            margins: {
              "right": 10
            },
            expected: {
              "x": 2000 - 10 - 40,
              "y": 0
            }
          },
          {
            tag: "bottom bar",
            anchors: {
              "bottom": true,
              "left": true,
              "right": true
            },
            margins: {
              "bottom": 6
            },
            expected: {
              "x": 0,
              "y": 1000 - 6 - 30
            }
          },
          {
            tag: "unanchored is centered",
            anchors: {},
            margins: {},
            expected: {
              "x": 980,
              "y": 485
            }
          }
        ];
  }

  function test_windowOrigin(data) {
    const vertical = data.anchors.top && data.anchors.bottom;
    const width = vertical ? 40 : (data.anchors.left && data.anchors.right ? 2000 : 40);
    const height = vertical ? 1000 : 30;
    compare(UiProbe.windowOrigin(data.anchors, data.margins, width, height, 2000, 1000), data.expected);
  }

  function test_globalRect() {
    compare(UiProbe.globalRect({
                                 "x": 731,
                                 "y": 1440
                               }, {
                                 "x": 8,
                                 "y": 4
                               }, {
                                 "x": 10.4,
                                 "y": 100.6
                               }, 32, 32.2), "749 1545 32 32");
  }
}
