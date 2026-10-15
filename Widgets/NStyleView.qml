import QtQuick
import qs.Commons

// Supply the view's interface at construction, before its bindings evaluate.
Loader {
  id: root
  required property string surface
  property var viewProperties: ({})
  readonly property string viewUrl: Style.surfaceUrl(surface)
  property bool ready: false

  function reloadView() {
    if (ready)
      setSource(viewUrl, viewProperties);
  }
  onViewUrlChanged: reloadView()
  onViewPropertiesChanged: reloadView()
  Component.onCompleted: {
    ready = true;
    reloadView();
  }
}
