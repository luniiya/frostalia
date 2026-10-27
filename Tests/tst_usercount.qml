import QtQuick
import QtTest
import "../Helpers/UserCount.js" as UserCount

TestCase {
  name: "UserCount"

  function test_add_and_remove() {
    let users = UserCount.add({}, "a");
    compare(users, {
              "a": 1
            });
    users = UserCount.remove(users, "a");
    compare(Object.keys(users).length, 0);
  }

  // Regression: the Edit Desktop card's copy of a widget shares the desktop widget's id,
  // and closing the editor used to drop the desktop widget's registration with it
  function test_shared_id_survives_one_removal() {
    let users = UserCount.add(UserCount.add({}, "desktop:lyrics:eDP-1:0"), "desktop:lyrics:eDP-1:0");
    users = UserCount.remove(users, "desktop:lyrics:eDP-1:0");
    compare(users["desktop:lyrics:eDP-1:0"], 1);
    users = UserCount.remove(users, "desktop:lyrics:eDP-1:0");
    verify(!("desktop:lyrics:eDP-1:0" in users));
  }

  function test_remove_unknown_is_harmless() {
    compare(UserCount.remove({
                               "a": 1
                             }, "b"), {
              "a": 1
            });
    compare(UserCount.remove(null, "b"), {});
  }

  function test_returns_new_objects() {
    const users = {
      "a": 1
    };
    verify(UserCount.add(users, "a") !== users);
    compare(users.a, 1);
    verify(UserCount.remove(users, "a") !== users);
    compare(users.a, 1);
  }
}
