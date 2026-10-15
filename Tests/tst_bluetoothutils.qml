import QtQuick
import QtTest
import "../Helpers/BluetoothUtils.js" as BT

TestCase {
  name: "BluetoothUtils"

  function test_macFromDevice() {
    compare(BT.macFromDevice(null), "");
    compare(BT.macFromDevice({
                               "address": "AA:BB:CC:DD:EE:FF"
                             }), "AA:BB:CC:DD:EE:FF");
    compare(BT.macFromDevice({
                               "nativePath": "/org/bluez/hci0/dev_AA_BB_CC_DD_EE_FF"
                             }), "AA:BB:CC:DD:EE:FF");
    compare(BT.macFromDevice({
                               "address": "",
                               "nativePath": "/org/bluez/hci0"
                             }), "");
  }

  function test_deviceKey() {
    compare(BT.deviceKey(null), "");
    compare(BT.deviceKey({
                           "address": "aa:bb:cc"
                         }), "AA:BB:CC");
    compare(BT.deviceKey({
                           "nativePath": "/x/dev_1"
                         }), "/x/dev_1");
    compare(BT.deviceKey({
                           "devicePath": "/y"
                         }), "/y");
    compare(BT.deviceKey({
                           "name": "Buds",
                           "icon": "audio-headset"
                         }), "Buds|audio-headset");
  }

  function test_dedupeDevices() {
    compare(BT.dedupeDevices(null).length, 0);
    compare(BT.dedupeDevices([]).length, 0);
    var a = {
      "address": "aa:bb"
    };
    var b = {
      "address": "AA:BB"
    }; // same device, different case
    var c = {
      "address": "cc:dd"
    };
    var out = BT.dedupeDevices([a, null, b, c, a]);
    compare(out.length, 2);
    verify(out[0] === a);
    verify(out[1] === c);
  }

  function test_parseRssiOutput_data() {
    return [
          {
            tag: "parenthesised dBm",
            text: "RSSI: 0xffffffc4 (-60)",
            expected: -60
          },
          {
            tag: "parenthesised with unit",
            text: "signal ( -45 dBm )",
            expected: -45
          },
          {
            tag: "decimal",
            text: "RSSI: -72",
            expected: -72
          },
          {
            tag: "hex 8-bit",
            text: "RSSI: 0xc4",
            expected: -60
          },
          {
            tag: "hex 16-bit",
            text: "RSSI: 0xffc4",
            expected: -60
          },
          {
            tag: "hex 32-bit",
            text: "RSSI: 0xffffffc4",
            expected: -60
          },
          {
            tag: "hex positive",
            text: "RSSI: 0x10",
            expected: 16
          },
          {
            tag: "garbage",
            text: "no signal here",
            expected: null
          },
          {
            tag: "empty",
            text: "",
            expected: null
          },
          {
            tag: "null",
            text: null,
            expected: null
          }
        ];
  }

  function test_parseRssiOutput(data) {
    compare(BT.parseRssiOutput(data.text), data.expected);
  }

  function test_dbmToPercent() {
    compare(BT.dbmToPercent(-100), 0);
    compare(BT.dbmToPercent(-70), 60);
    compare(BT.dbmToPercent(-50), 100);
    compare(BT.dbmToPercent(-20), 100); // clamps high
    compare(BT.dbmToPercent(-130), 0); // clamps low
    compare(BT.dbmToPercent(null), null);
    compare(BT.dbmToPercent(undefined), null);
    compare(BT.dbmToPercent(NaN), null);
  }

  function test_signalPercent() {
    compare(BT.signalPercent(null, {}, 0), null);
    var dev = {
      "address": "AA:BB",
      "signalStrength": 40
    };
    compare(BT.signalPercent(dev, {}, 0), 40);
    compare(BT.signalPercent(dev, {
                               "AA:BB": 85
                             }, 0), 85); // cache wins
    compare(BT.signalPercent(dev, {
                               "AA:BB": 150
                             }, 0), 100); // clamped
    compare(BT.signalPercent({
                               "signalStrength": 0
                             }, null, 0), null);
    compare(BT.signalPercent({
                               "signalStrength": 250
                             }, null, 0), 100);
  }

  function test_signalIcon() {
    compare(BT.signalIcon(null), "antenna-bars-off");
    compare(BT.signalIcon(100), "antenna-bars-5");
    compare(BT.signalIcon(80), "antenna-bars-5");
    compare(BT.signalIcon(79), "antenna-bars-4");
    compare(BT.signalIcon(60), "antenna-bars-4");
    compare(BT.signalIcon(40), "antenna-bars-3");
    compare(BT.signalIcon(20), "antenna-bars-2");
    compare(BT.signalIcon(19), "antenna-bars-1");
    compare(BT.signalIcon(0), "antenna-bars-1");
  }

  function test_deviceIcon_data() {
    return [
          {
            tag: "earbuds by name",
            name: "AirPods Pro",
            icon: "",
            expected: "bt-device-earbuds"
          },
          {
            tag: "galaxy buds",
            name: "Galaxy Buds2",
            icon: "audio-headset",
            expected: "bt-device-earbuds"
          },
          {
            tag: "headset",
            name: "SteelSeries Arctis 7",
            icon: "",
            expected: "bt-device-headset"
          },
          {
            tag: "headphones",
            name: "Sony Headphones",
            icon: "",
            expected: "bt-device-headphones"
          },
          {
            tag: "gamepad",
            name: "Xbox Wireless Controller",
            icon: "input-gaming",
            expected: "bt-device-gamepad"
          },
          {
            tag: "mouse",
            name: "MX Master 3",
            icon: "input-mouse",
            expected: "bt-device-mouse"
          },
          {
            tag: "keyboard",
            name: "K380",
            icon: "input-keyboard",
            expected: "bt-device-keyboard"
          },
          {
            tag: "watch",
            name: "Pixel Watch",
            icon: "",
            expected: "bt-device-watch"
          },
          {
            tag: "phone",
            name: "My iPhone",
            icon: "phone",
            expected: "bt-device-phone"
          },
          {
            tag: "speaker",
            name: "JBL Flip",
            icon: "audio-card",
            expected: "bt-device-speaker"
          },
          {
            tag: "tv icon beats audio name",
            name: "Living Room Audio",
            icon: "video-display",
            expected: "bt-device-tv"
          },
          {
            tag: "microphone",
            name: "Blue Microphone",
            icon: "",
            expected: "bt-device-microphone"
          },
          {
            tag: "unknown",
            name: "Thing",
            icon: "",
            expected: "bt-device-generic"
          },
          {
            tag: "nulls",
            name: null,
            icon: undefined,
            expected: "bt-device-generic"
          }
        ];
  }

  function test_deviceIcon(data) {
    compare(BT.deviceIcon(data.name, data.icon), data.expected);
  }

  function test_batteryPercent() {
    compare(BT.batteryPercent(null), null);
    compare(BT.batteryPercent({
                                "batteryAvailable": false,
                                "battery": 0.5
                              }), null);
    compare(BT.batteryPercent({
                                "batteryAvailable": true
                              }), null);
    compare(BT.batteryPercent({
                                "batteryAvailable": true,
                                "battery": 0.456
                              }), 46);
    compare(BT.batteryPercent({
                                "batteryAvailable": true,
                                "battery": 1.2
                              }), 100);
    compare(BT.batteryPercent({
                                "batteryAvailable": true,
                                "battery": "x"
                              }), null);
  }
}
