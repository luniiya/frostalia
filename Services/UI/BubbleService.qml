pragma Singleton

import QtQuick
import Quickshell
import "../../Helpers/BubbleLogic.js" as BubbleLogic
import "../../Helpers/QtObj2JS.js" as QtObj2JS
import qs.Commons

Singleton {
  id: root

  readonly property var defaults: QtObj2JS.qtObjectToPlainObject(Settings.data.bubbles.defaults)
  property var sizes: ({})

  function hasBubbles(screenName) {
    return BubbleLogic.wantsPanels(Settings.data.bubbles.enabled, Settings.data.bubbles.configurations, screenName);
  }

  function measure(screenName, id, width, height) {
    var key = screenName + "|" + id;
    var previous = sizes[key];
    if (previous && previous.width === width && previous.height === height)
      return;
    var updated = Object.assign({}, sizes);
    updated[key] = {
      width: width,
      height: height
    };
    sizes = updated;
  }

  function forget(screenName, id) {
    var updated = Object.assign({}, sizes);
    delete updated[screenName + "|" + id];
    sizes = updated;
  }
}
