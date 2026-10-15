import QtQuick
import QtTest
import "../Helpers/SettingsWindowRequest.js" as SettingsWindowRequest

TestCase {
  name: "SettingsWindowRequest"

  function test_tab_data() {
    return [
          {
            tag: "tab only",
            tab: 5,
            subTab: -1,
            expectedTab: 5,
            expectedSubTab: -1
          },
          {
            tag: "tab and subtab",
            tab: 20,
            subTab: 1,
            expectedTab: 20,
            expectedSubTab: 1
          },
          {
            tag: "subtab zero kept",
            tab: 3,
            subTab: 0,
            expectedTab: 3,
            expectedSubTab: 0
          },
          {
            tag: "undefined subtab",
            tab: 2,
            subTab: undefined,
            expectedTab: 2,
            expectedSubTab: -1
          },
          {
            tag: "null subtab",
            tab: 2,
            subTab: null,
            expectedTab: 2,
            expectedSubTab: -1
          },
          {
            tag: "undefined tab",
            tab: undefined,
            subTab: -1,
            expectedTab: 0,
            expectedSubTab: -1
          },
          {
            tag: "negative tab",
            tab: -3,
            subTab: 2,
            expectedTab: 0,
            expectedSubTab: 2
          }
        ];
  }

  function test_tab(data) {
    var r = SettingsWindowRequest.resolve(data.tab, data.subTab, null);
    compare(r.kind, "tab");
    compare(r.tab, data.expectedTab);
    compare(r.subTab, data.expectedSubTab);
  }

  // Regression: window mode used to open only requestedTab, dropping the
  // requested subtab and search entry.
  function test_entryWinsOverTab() {
    var entry = {
      "tab": 7,
      "subTab": 2,
      "labelKey": "x"
    };
    var r = SettingsWindowRequest.resolve(1, 3, entry);
    compare(r.kind, "entry");
    verify(r.entry === entry);
  }
}
