import QtQuick
import QtTest
import "../Helpers/PowerProfiles.js" as PowerProfiles

TestCase {
  name: "PowerProfiles"

  // Stand-ins for PowerProfile.PowerSaver, Balanced and Performance
  readonly property int powerSaver: 0
  readonly property int balanced: 1
  readonly property int performance: 2

  function test_labelKey_data() {
    return [
          {
            tag: "power saver",
            available: true,
            profile: powerSaver,
            key: "common.power-saver"
          },
          {
            tag: "balanced",
            available: true,
            profile: balanced,
            key: "common.balanced"
          },
          {
            tag: "performance",
            available: true,
            profile: performance,
            key: "common.performance"
          },
          {
            tag: "unknown profile",
            available: true,
            profile: 7,
            key: "common.unknown"
          },
          {
            tag: "no power-profiles-daemon",
            available: false,
            profile: balanced,
            key: "common.unknown"
          }
        ];
  }

  function test_labelKey(data) {
    compare(PowerProfiles.labelKey(data.available, data.profile, powerSaver, balanced, performance), data.key);
  }
}
