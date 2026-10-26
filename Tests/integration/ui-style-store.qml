import QtQuick
import Quickshell
import Quickshell.Io
import "../../Commons"
import "../../Helpers/UiStyleSettings.js" as UiStyleSettings
import "../../Helpers/UiStyles.js" as UiStyles

ShellRoot {
  id: root
  property int phase: 0

  JsonAdapter {
    id: model
    property JsonObject general: JsonObject {
      property real scaleRatio: 1
      property real radiusRatio: 1
      property real screenRadiusRatio: 1.3
    }
    property JsonObject ui: JsonObject {
      property string style: "keycap"
      property string fontDefault: ""
      property real fontDefaultScale: 1.1
      property real panelBackgroundOpacity: 0.93
    }
  }

  function check(condition, message) {
    if (condition)
      return true;
    console.error("STORE_FAILURE: " + message);
    Qt.quit();
    return false;
  }

  TomlSettingsStore {
    id: store
    adapter: model
    configFile: Quickshell.env("FROSTALIA_TEST_CONFIG")
    helper: Quickshell.env("FROSTALIA_SETTINGS_HELPER")
    uiProfiles: UiStyleSettings.configuration(configFile.substring(0, configFile.lastIndexOf("/")) + "/UI", UiStyles.loadAll(Qt.resolvedUrl("../../Styles"), ["material", "keycap"]))
    active: true
    onFailed: message => {
      console.error("STORE_FAILURE: " + message);
      Qt.quit();
    }
    onLoaded: function (raw, fresh) {
      if (!root.check(!switchingStyle, "style transition must finish before loaded"))
        return;
      if (root.phase === 0) {
        if (!root.check(!store.switchStyle("../../invalid"), "invalid style accepted"))
          return;
        model.general.radiusRatio = 0.4;
        model.ui.fontDefault = "Keycap Font";
        model.general.scaleRatio = 1.15;
        root.phase = 1;
        ipcSwitch.running = true;
      } else if (root.phase === 1) {
        if (!root.check(model.ui.style === "material" && model.general.radiusRatio === 1 && model.ui.fontDefault === "Roboto" && model.ui.panelBackgroundOpacity === 1, "Material must load its own defaults"))
          return;
        if (!root.check(model.general.scaleRatio === 1.15 && model.general.screenRadiusRatio === 1.3 && model.ui.fontDefaultScale === 1.1, "host values changed"))
          return;
        model.general.radiusRatio = 0.2;
        model.ui.fontDefault = "Material Font";
        root.phase = 2;
        store.switchStyle("keycap");
      } else if (root.phase === 2) {
        if (!root.check(model.ui.style === "keycap" && model.general.radiusRatio === 0.4 && model.ui.fontDefault === "Keycap Font", "Keycap edits lost"))
          return;
        root.phase = 3;
        store.switchStyle("material");
      } else if (root.phase === 3) {
        if (!root.check(model.general.radiusRatio === 0.2 && model.ui.fontDefault === "Material Font", "Material edits lost"))
          return;
        root.phase = 4;
        externalEdit.running = true;
      } else if (root.phase === 4 && model.general.radiusRatio === 0.7) {
        if (!root.check(model.ui.fontDefault === "External" && model.ui.panelBackgroundOpacity === 1, "external edit/default resolution failed"))
          return;
        root.phase = 5;
        store.switchStyle("keycap");
      } else if (root.phase === 5 && model.ui.style === "keycap") {
        if (!root.check(model.general.radiusRatio === 0.4, "external Material edit leaked into Keycap"))
          return;
        console.log("STORE_SUCCESS");
        Qt.quit();
      }
    }
  }

  Process {
    id: ipcSwitch
    command: ["qs", "ipc", "-p", Quickshell.shellDir, "call", "uiStyle", "set", "material"]
    stdout: StdioCollector {
      id: ipcOutput
    }
    stderr: StdioCollector {
      id: ipcErrors
    }
    onExited: exitCode => root.check(exitCode === 0 && ipcOutput.text.trim() === "true", "IPC style switch failed: " + ipcErrors.text + ipcOutput.text)
  }

  Process {
    id: externalEdit
    command: ["python3", "-c", "import pathlib,sys; p=pathlib.Path(sys.argv[1]); q=p.with_suffix('.tmp'); q.write_text(\"# manual profile edit\\n[general]\\nradiusRatio=0.7\\n[ui]\\nfontDefault='External'\\n\"); q.replace(p)", store.uiProfiles.directory + "/material.toml"]
  }

  Timer {
    running: true
    interval: 6000
    onTriggered: {
      console.error("STORE_FAILURE: timed out at phase " + root.phase);
      Qt.quit();
    }
  }
}
