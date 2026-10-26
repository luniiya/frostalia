import QtQuick
import qs.Commons

// Loads the active style's face for a bar widget (its definition's `barViews`), or
// nothing when the style keeps the shared look. A face only draws: the widget
// keeps its own mouse areas, tooltips and menus and feeds the face its state and
// the style's kit (Style.kit). Faces are loaded by URL, so a style folder of faces
// needs a qmldir for the faces to use each other as types.
Loader {
  id: root

  // Face name; `fallbackView` is used when the style has no face of that name.
  property string view: ""
  property string fallbackView: ""
  property Item host: null
  property bool hovered: false
  property bool pressed: false
  property var faceData: ({})
  property real depth: Style.faceDepth

  readonly property string url: Style.barViewUrl(view) || (fallbackView ? Style.barViewUrl(fallbackView) : "")
  readonly property bool loaded: status === Loader.Ready && item !== null
  // Offset the host applies to content it draws itself, so it sinks with the face.
  readonly property real sink: loaded ? item.sink : 0
  readonly property bool ownsIcon: loaded && item.ownsIcon
  readonly property bool ownsContent: loaded && item.ownsContent
  // Content color the face asks for (transparent: keep the host's own colors).
  readonly property color contentColor: loaded ? item.contentColor : "transparent"

  active: url !== ""
  onUrlChanged: load()
  Component.onCompleted: load()

  property string _loadedUrl: ""

  function load() {
    if (url === _loadedUrl)
      return;
    _loadedUrl = url;
    if (url)
      setSource(url, {
                  "kit": Style.kit,
                  "host": root.host
                });
    else
      source = "";
  }

  // Lets a host replay a face's pop-in animation (e.g. on a new notification).
  function bump() {
    if (loaded && item.bump)
      item.bump();
  }

  Binding {
    target: root.item
    property: "hovered"
    value: root.hovered
    when: root.loaded
  }
  Binding {
    target: root.item
    property: "pressed"
    value: root.pressed
    when: root.loaded
  }
  Binding {
    target: root.item
    property: "faceData"
    value: root.faceData
    when: root.loaded
  }
  Binding {
    target: root.item
    property: "depth"
    value: root.depth
    when: root.loaded
  }
}
