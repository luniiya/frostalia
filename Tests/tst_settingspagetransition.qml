import QtQuick
import QtTest
import "../Modules/Panels/Settings" as SettingsViews

TestCase {
  name: "SettingsPageTransition"
  when: windowShown

  Component {
    id: transitionComponent
    SettingsViews.SettingsPageTransition {
      duration: 160
    }
  }

  function test_sidebarAndPagesAnimateTogether() {
    const transition = createTemporaryObject(transitionComponent, this);
    compare(transition.progress, 0);
    transition.pageVisible = true;
    tryCompare(transition, "transitioning", true);
    wait(60);
    verify(transition.progress > 0 && transition.progress < 1);
    tryCompare(transition, "progress", 1);
    transition.pageVisible = false;
    tryCompare(transition, "transitioning", true);
    wait(60);
    verify(transition.progress > 0 && transition.progress < 1, "outgoing content stays visible until the fade completes");
    tryCompare(transition, "progress", 0);
  }

  function test_reverseWhileOpening() {
    const transition = createTemporaryObject(transitionComponent, this);
    transition.pageVisible = true;
    wait(60);
    const partial = transition.progress;
    verify(partial > 0 && partial < 1);
    transition.pageVisible = false;
    verify(transition.progress <= partial);
    tryCompare(transition, "progress", 0);
  }

  function test_disabledAnimations() {
    const transition = createTemporaryObject(transitionComponent, this, {
                                               duration: 0
                                             });
    transition.pageVisible = true;
    compare(transition.progress, 1);
    transition.pageVisible = false;
    compare(transition.progress, 0);
    verify(!transition.transitioning);
  }
}
