import QtQuick
import QtTest
import "../Helpers/LockCommand.js" as LockCommand

TestCase {
  name: "LockCommand"

  function test_resolve_data() {
    return [
          {
            tag: "default locker",
            configured: "hyprlock",
            action: "",
            expected: "hyprlock"
          },
          {
            tag: "custom locker",
            configured: "swaylock",
            action: "",
            expected: "swaylock"
          },
          {
            tag: "session action override",
            configured: "hyprlock",
            action: " loginctl lock-session ",
            expected: "loginctl lock-session"
          },
          {
            tag: "blank command",
            configured: "  ",
            action: "",
            expected: ""
          }
        ];
  }

  function test_resolve(data) {
    compare(LockCommand.resolve(data.configured, data.action), data.expected);
  }
}
