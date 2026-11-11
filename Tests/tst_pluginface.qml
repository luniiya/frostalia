import QtQuick
import QtTest
import "../Helpers/PluginFace.js" as PluginFace

TestCase {
  name: "PluginFace"

  function rect(width, height, extra) {
    return Object.assign({
                           visible: true,
                           radius: 8,
                           width: width,
                           height: height,
                           color: {
                             a: 1
                           },
                           border: {
                             width: 0
                           },
                           children: []
                         }, extra || {});
  }

  function test_isCapsule_data() {
    return [
          {
            tag: "capsule spanning the widget",
            candidate: rect(60, 26),
            expected: true
          },
          {
            tag: "small icon chip",
            candidate: rect(14, 14),
            expected: false
          },
          {
            tag: "thin progress bar",
            candidate: rect(60, 3),
            expected: false
          },
          {
            tag: "hidden",
            candidate: rect(60, 26, {
                              visible: false
                            }),
            expected: false
          },
          {
            tag: "transparent without border",
            candidate: rect(60, 26, {
                              color: {
                                a: 0
                              }
                            }),
            expected: false
          },
          {
            tag: "outline only",
            candidate: rect(60, 26, {
                              color: {
                                a: 0
                              },
                              border: {
                                width: 2
                              }
                            }),
            expected: true
          },
          {
            tag: "not a rectangle",
            candidate: {
              visible: true,
              width: 60,
              height: 26
            },
            expected: false
          }
        ];
  }

  function test_isCapsule(data) {
    compare(PluginFace.isCapsule(data.candidate, 64, 40, 26, false), data.expected);
  }

  function test_verticalBarsMeasureAlongTheHeight() {
    verify(PluginFace.isCapsule(rect(26, 60), 40, 64, 26, true));
    verify(!PluginFace.isCapsule(rect(60, 26), 40, 64, 26, true));
  }

  function test_capsulesFindsBackgroundsButNotContent() {
    const chip = rect(14, 14);
    const capsule = rect(62, 26, {
                           children: [chip, rect(60, 26)]
                         });
    const icon = {
      visible: true,
      width: 20,
      height: 20,
      children: []
    };
    const wrapper = {
      visible: true,
      width: 64,
      height: 40,
      children: [rect(64, 26)]
    };
    const host = {
      width: 64,
      height: 40,
      children: [capsule, icon, wrapper]
    };
    const found = PluginFace.capsules(host, 26, false);
    compare(found.length, 2);
    verify(found[0] === capsule);
    verify(found[1] === wrapper.children[0]);
    compare(PluginFace.capsules(null, 26, false).length, 0);
  }
}
