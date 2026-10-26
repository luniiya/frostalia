import QtQuick
import qs.Commons

// Draws a shared control in the active UI style: loads Styles/<style>/<name>.qml
// and hands it `control`, the item it draws. The control keeps its behavior and
// input handling; the skin only draws and reports back what the control asks of
// it (e.g. `contentColor` or `sink`). Every style folder has every skin
// (Tests/python/test_style_folders.py).
Loader {
  id: root

  property string name: ""
  property Item control: parent

  readonly property string url: name ? Style.skinUrl(name) : ""
  readonly property bool loaded: status === Loader.Ready && item !== null

  anchors.fill: parent
  onUrlChanged: load()
  Component.onCompleted: load()

  property string _loadedUrl: ""

  function load() {
    if (url === _loadedUrl)
      return;
    _loadedUrl = url;
    if (url)
      setSource(url, {
                  "control": root.control
                });
    else
      source = "";
  }
}
