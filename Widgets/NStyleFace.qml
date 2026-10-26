import QtQuick
import qs.Commons
// Faces are only loaded by URL. Quickshell indexes the directories it reaches through
// imports, so without this the faces can't use each other as types ("KeycapFace is not a type").
import qs.Modules.Bar.Widgets.Keycap

// Loads the active style's face for a bar widget (UiStyles `barViews`), or
// nothing when the style keeps the shared look. A face only draws: the widget
// keeps its own mouse areas, tooltips and menus and feeds the face its state.
// Faces derive from Modules/Bar/Widgets/Keycap/KeycapFace.qml.
Loader {
  id: root

  // Face name; `fallbackView` is used when the style has no face of that name.
  property string view: ""
  property string fallbackView: ""
  property Item host: null
  property bool hovered: false
  property bool pressed: false
  property var faceData: ({})
  property real depth: Style.keycapDepth

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
                  "kit": KeycapKit,
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
