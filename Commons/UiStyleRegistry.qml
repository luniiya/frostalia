pragma Singleton

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import "../Helpers/UiStyles.js" as UiStyles

// Finds the UI styles: every folder in Styles/ with a Definition.qml is one.
// The default style is loaded straight away so the shell can draw before the
// folder listing arrives; Settings waits for `ready` to load the style profiles.
Singleton {
  id: root

  readonly property string directory: Quickshell.shellDir + "/Styles"
  // id -> plain definition (UiStyles.fromDefinition())
  property var definitions: UiStyles.loadAll(directory, [UiStyles.defaultStyle])
  property bool ready: false
  readonly property var choices: UiStyles.choices(definitions)

  function scan() {
    const ids = [];
    for (let i = 0; i < folders.count; i++)
      ids.push(folders.get(i, "fileName"));
    definitions = UiStyles.loadAll(directory, ids);
    if (!definitions[UiStyles.defaultStyle])
      console.warn("UiStyleRegistry: the default style", UiStyles.defaultStyle, "is missing from", directory);
    ready = true;
  }

  property FolderListModel folders: FolderListModel {
    folder: "file://" + root.directory
    showFiles: false
    showDirs: true
    showDotAndDotDot: false
    showHidden: false
    sortField: FolderListModel.Name
    onStatusChanged: {
      if (status === FolderListModel.Ready)
        root.scan();
    }
  }
}
