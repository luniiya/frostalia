import QtQuick
import Quickshell
import Quickshell.Io
import "../../Commons"

ShellRoot {
  id: root
  property int loads: 0
  property int phase: 0

  JsonAdapter {
    id: model
    property int settingsVersion: 65
    property JsonObject bar: JsonObject {
      property string position: "top"
      property list<var> widgets: [
        {
          id: "Clock"
        }
      ]
    }
    property JsonObject general: JsonObject {
      property bool animationDisabled: false
    }
  }

  TomlSettingsStore {
    id: store
    adapter: model
    configFile: Quickshell.env("FROSTALIA_TEST_CONFIG")
    helper: Quickshell.env("FROSTALIA_SETTINGS_HELPER")
    active: true
    onFailed: message => {
      console.error("STORE_FAILURE: " + message);
      Qt.quit();
    }
    onChanged: saveTimer.restart()
    onLoaded: function (raw, fresh) {
      root.loads++;
      console.log("STORE_LOADED", root.loads, fresh, model.bar.position);
      if (root.phase === 0) {
        if (!fresh || model.bar.position !== "top") {
          console.error("STORE_FAILURE: first-install defaults");
          Qt.quit();
          return;
        }
        root.phase = 1;
        model.bar.position = "bottom";
      } else if (root.phase === 1 && model.bar.position === "bottom") {
        root.phase = 2;
        externalEdit.contents = "# keep my comment\n[bar]\nposition = 'left'\n[general]\nanimationDisabled = true\n";
        externalEdit.running = true;
      } else if (root.phase === 2 && model.bar.position === "left" && model.general.animationDisabled) {
        root.phase = 3;
        model.general.animationDisabled = false;
      } else if (root.phase === 3 && !model.general.animationDisabled) {
        root.phase = 4;
        externalEdit.contents = "# keep my comment\n[bar]\nposition = 'right'\n[general]\nanimationDisabled = false\n";
        externalEdit.running = true;
      } else if (root.phase === 4 && model.bar.position === "right") {
        console.log("STORE_SUCCESS");
        Qt.quit();
      }
    }
  }
  Process {
    id: externalEdit
    property string contents: ""
    command: ["python3", "-c", "import pathlib,sys; p=pathlib.Path(sys.argv[1]); q=p.with_suffix('.tmp'); q.write_text(sys.argv[2]); q.replace(p)", store.configFile, contents]
  }
  Timer {
    id: saveTimer
    interval: 10
    onTriggered: store.save()
  }
  Timer {
    running: true
    interval: 6000
    onTriggered: {
      console.error("STORE_FAILURE: timed out");
      Qt.quit();
    }
  }
}
