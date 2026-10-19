import QtQuick
import QtTest
import "../Modules/Panels/Settings" as SettingsViews

TestCase {
  name: "SettingsSidebar"

  Item {
    id: reveal
    width: 0
    height: 700

    SettingsViews.SettingsSidebarLayout {
      id: viewport
      viewportWidth: 224
    }
  }

  function test_viewportSurvivesPageReveal_data() {
    return [
          {
            tag: "hidden",
            revealWidth: 0
          },
          {
            tag: "opening",
            revealWidth: 12
          },
          {
            tag: "halfway",
            revealWidth: 112
          },
          {
            tag: "open",
            revealWidth: 224
          }
        ];
  }

  function test_viewportSurvivesPageReveal(data) {
    reveal.width = data.revealWidth;
    compare(viewport.width, 224);
    compare(viewport.height, 700);
  }

  function test_compactAndInset() {
    viewport.viewportWidth = 48;
    compare(viewport.width, 48);
    viewport.inset = 6;
    compare(viewport.width, 36);
    compare(viewport.x, 6);
    compare(viewport.y, 6);
    compare(viewport.height, 688);
    viewport.inset = 0;
    viewport.viewportWidth = 224;
  }
}
