import QtQuick
import QtTest
import "../Helpers/AudioVolume.js" as AudioVolume

TestCase {
  name: "AudioVolume"

  function test_maxOutputVolume_data() {
    return [
          {
            tag: "off",
            overdrive: false,
            selectedOnly: false,
            allowed: [],
            node: {
              name: "speakers"
            },
            expected: 1.0
          },
          {
            tag: "all devices",
            overdrive: true,
            selectedOnly: false,
            allowed: [],
            node: {
              name: "speakers"
            },
            expected: 1.5
          },
          {
            tag: "selected device",
            overdrive: true,
            selectedOnly: true,
            allowed: ["speakers"],
            node: {
              name: "speakers"
            },
            expected: 1.5
          },
          {
            tag: "other device",
            overdrive: true,
            selectedOnly: true,
            allowed: ["speakers"],
            node: {
              name: "headphones"
            },
            expected: 1.0
          },
          {
            tag: "no device",
            overdrive: true,
            selectedOnly: true,
            allowed: ["speakers"],
            node: null,
            expected: 1.0
          },
          {
            tag: "properties name",
            overdrive: true,
            selectedOnly: true,
            allowed: ["alsa_output.pci"],
            node: {
              properties: {
                "node.name": "alsa_output.pci"
              }
            },
            expected: 1.5
          }
        ];
  }

  function test_maxOutputVolume(data) {
    compare(AudioVolume.maxOutputVolume(data.overdrive, data.selectedOnly, data.allowed, data.node), data.expected);
  }

  function test_withDeviceAllowed() {
    const speakers = {
      name: "speakers"
    };
    const original = ["headphones"];
    const added = AudioVolume.withDeviceAllowed(original, speakers, true);
    compare(original, ["headphones"]);
    compare(added, ["headphones", "speakers"]);
    compare(AudioVolume.withDeviceAllowed(added, speakers, true), added);
    compare(AudioVolume.withDeviceAllowed(added, speakers, false), original);
    compare(AudioVolume.withDeviceAllowed(original, null, true), original);
  }

  function test_isAboveNormalVolume_data() {
    return [
          {
            tag: "below",
            volume: 0.99,
            expected: false
          },
          {
            tag: "exactly 100 percent",
            volume: 1.0,
            expected: false
          },
          {
            tag: "above 100 percent",
            volume: 1.01,
            expected: true
          },
          {
            tag: "maximum boost",
            volume: 1.5,
            expected: true
          },
          {
            tag: "missing",
            volume: null,
            expected: false
          }
        ];
  }

  function test_isAboveNormalVolume(data) {
    compare(AudioVolume.isAboveNormalVolume(data.volume), data.expected);
  }

  function test_widgetColor_data() {
    return [
          {
            tag: "normal volume",
            volume: 1.0,
            configured: "#ff0000",
            expected: "normal"
          },
          {
            tag: "default color",
            volume: 1.2,
            configured: "",
            expected: "normal"
          },
          {
            tag: "custom color",
            volume: 1.2,
            configured: "#ab12ef",
            expected: "#ab12ef"
          },
          {
            tag: "short hex color",
            volume: 1.2,
            configured: "#f0a",
            expected: "#f0a"
          },
          {
            tag: "invalid color",
            volume: 1.2,
            configured: "red",
            expected: "normal"
          },
          {
            tag: "incomplete color",
            volume: 1.2,
            configured: "#1234",
            expected: "normal"
          }
        ];
  }

  function test_widgetColor(data) {
    compare(AudioVolume.widgetColor(data.volume, data.configured, "normal"), data.expected);
  }
}
