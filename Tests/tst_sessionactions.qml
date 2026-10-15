import QtQuick
import QtTest
import "../Helpers/SessionActions.js" as SessionActions

TestCase {
  name: "SessionActions"

  function test_withoutLock() {
    const saved = [
            {
              action: "lock",
              keybind: "1"
            },
            {
              action: "suspend",
              keybind: "2",
              command: "custom-suspend"
            },
            {
              action: "shutdown",
              keybind: "6"
            }
          ];
    const cleaned = SessionActions.withoutLock(saved);
    compare(cleaned.length, 2);
    compare(cleaned[0].action, "suspend");
    compare(cleaned[0].command, "custom-suspend");
    compare(cleaned[1].action, "shutdown");
    compare(saved.length, 3);
  }

  function test_withoutLock_keepsUnchangedList() {
    const saved = [
            {
              action: "suspend"
            }
          ];
    verify(SessionActions.withoutLock(saved) === saved);
    compare(SessionActions.withoutLock(null), null);
  }

  function test_withExternalLock_addsAndRenumbers() {
    const saved = [
            {
              action: "suspend",
              enabled: true,
              keybind: "1",
              command: "custom-suspend"
            },
            {
              action: "logout",
              enabled: true,
              keybind: "Ctrl+L"
            }
          ];
    const updated = SessionActions.withExternalLock(saved, null);
    compare(updated.map(option => option.action), ["lock", "suspend", "logout"]);
    compare(updated.map(option => option.keybind), ["1", "2", "Ctrl+L"]);
    compare(updated[1].command, "custom-suspend");
    compare(saved[0].keybind, "1");
    verify(SessionActions.withExternalLock(updated, null) === updated);
  }

  function test_withExternalLock_preservesPreviousLock() {
    const previous = {
      action: "lock",
      enabled: false,
      keybind: "1",
      command: "swaylock"
    };
    const updated = SessionActions.withExternalLock([
                                                      {
                                                        action: "suspend",
                                                        keybind: "2"
                                                      }
                                                    ], previous);
    compare(updated[0].command, "swaylock");
    compare(updated[0].enabled, false);
    compare(updated[1].keybind, "2");
  }
}
