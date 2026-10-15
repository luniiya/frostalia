.pragma library

// Decides what the standalone settings window should show when a caller
// opens settings through SettingsPanel (settings always open in a window).
// Kept free of QML dependencies so it can be unit tested
// (see Tests/tst_settingswindowrequest.qml).
//
// Returns { kind: "entry", entry } for a search result, otherwise
// { kind: "tab", tab, subTab } where subTab is -1 when none was requested.
function resolve(requestedTab, requestedSubTab, requestedEntry) {
  if (requestedEntry)
    return {
      "kind": "entry",
      "entry": requestedEntry
    };
  var tab = (typeof requestedTab === "number" && requestedTab >= 0) ? requestedTab : 0;
  var subTab = (typeof requestedSubTab === "number" && requestedSubTab >= 0) ? requestedSubTab : -1;
  return {
    "kind": "tab",
    "tab": tab,
    "subTab": subTab
  };
}
