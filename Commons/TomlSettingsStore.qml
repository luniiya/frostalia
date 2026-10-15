import QtQuick
import Quickshell
import Quickshell.Io
import "../Helpers/QtObj2JS.js" as QtObj2JS
import "../Helpers/SettingsObject.js" as SettingsObject

// Disk storage for the QML settings model. JSON is only the private IPC protocol.
Item {
  id: root
  visible: false

  required property var adapter
  required property string configFile
  property list<string> seedFiles: []
  property string helper: Quickshell.env("FROSTALIA_SETTINGS_HELPER") || (Quickshell.shellDir + "/Tools/settings/target/release/frostalia-settings")
  property bool active: false
  property bool componentReady: false
  property bool initialized: false
  property bool applying: false
  property bool loadPending: false
  property bool savePending: false
  property var defaults: null
  property var settingsBaseline: null
  property var sentSettings: null
  property string operation: ""
  property var input: null
  property string error: ""

  signal loaded(var rawSettings, bool fresh)
  signal saved
  signal changed
  signal failed(string message)

  function snapshot() {
    return QtObj2JS.qtObjectToPlainObject(adapter);
  }

  function reload() {
    loadPending = true;
    pump();
  }

  function save() {
    if (!initialized)
      return;
    savePending = true;
    pump();
  }

  function pump() {
    if (!componentReady || !active || process.running)
      return;
    if (!defaults)
      defaults = snapshot();
    // Flush pending UI edits before accepting a manual file reload.
    if (loadPending && initialized && JSON.stringify(snapshot()) !== JSON.stringify(settingsBaseline))
      savePending = true;
    if (savePending && initialized) {
      savePending = false;
      operation = "save";
      sentSettings = snapshot();
      input = {
        settings: sentSettings,
        baseline: settingsBaseline
      };
      process.command = [helper, "save", configFile];
    } else if (loadPending) {
      loadPending = false;
      operation = "load";
      sentSettings = snapshot();
      input = {
        settings: defaults
      };
      process.command = [helper, "load", configFile].concat(Array.from(seedFiles));
    } else {
      return;
    }
    process.running = true;
  }

  Component.onCompleted: {
    componentReady = true;
    if (active)
      reload();
  }

  onActiveChanged: {
    if (active)
      reload();
  }

  Connections {
    target: root.adapter
    function onAdapterUpdated() {
      if (root.initialized && !root.applying)
        root.changed();
    }
  }

  Timer {
    id: reloadTimer
    interval: 200
    onTriggered: root.reload()
  }

  FileView {
    path: root.active && root.componentReady ? root.configFile : ""
    printErrors: false
    watchChanges: true
    onFileChanged: reloadTimer.restart()
  }

  // Retain watching across atomic replacements and declarative symlink swaps.
  FileView {
    path: root.initialized ? root.configFile.substring(0, root.configFile.lastIndexOf("/") + 1) : ""
    printErrors: false
    watchChanges: true
    onFileChanged: reloadTimer.restart()
  }

  Process {
    id: process
    stdinEnabled: true
    stdout: StdioCollector {
      id: output
    }
    stderr: StdioCollector {
      id: errors
    }
    onStarted: write(JSON.stringify(root.input) + "\n")
    onExited: function (exitCode) {
      if (exitCode !== 0) {
        root.error = errors.text.trim() || "Settings helper failed (exit " + exitCode + ")";
        root.loadPending = false;
        root.savePending = false;
        root.failed(root.error);
        return;
      }
      try {
        const result = JSON.parse(output.text);
        root.error = "";
        if (root.operation === "load") {
          const edits = SettingsObject.changes(root.sentSettings, root.snapshot());
          root.applying = true;
          SettingsObject.apply(root.adapter, root.defaults);
          SettingsObject.apply(root.adapter, result.settings);
          root.settingsBaseline = root.snapshot();
          SettingsObject.apply(root.adapter, edits);
          root.applying = false;
          root.initialized = true;
          root.loaded(result.settings, result.fresh);
          if (Object.keys(edits).length > 0)
            root.changed();
        } else {
          root.settingsBaseline = root.sentSettings;
          // Read the merged document, including manual edits retained by the helper.
          root.loadPending = true;
          root.saved();
        }
      } catch (e) {
        root.applying = false;
        root.error = "Could not load settings: " + e;
        root.failed(root.error);
      }
      Qt.callLater(root.pump);
    }
  }
}
