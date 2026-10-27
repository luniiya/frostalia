import QtQuick
import "../../Helpers/WallpaperVisualizer.js" as WallpaperVisualizer
import qs.Commons
import qs.Modules.WallpaperVisualizer
import qs.Services.UI

// What an effect from the shelf does, shown on the card while its tile is hovered (or the
// wave settings are open): the waves with the current settings, moving to a made-up beat.
// Previewing the depth effect draws the subject over them even while depth is off.
Item {
  id: root

  // "waves", "depth", "edges" or "" for none
  property string effect: ""
  property string wallpaper: ""
  property real devicePixelRatio: 1

  readonly property var prefs: Settings.data.wallpaperVisualizer
  readonly property bool showing: effect !== ""
  readonly property bool depth: effect === "depth" || prefs.depth
  property real elapsed: 0

  opacity: showing ? 1 : 0
  visible: opacity > 0

  Behavior on opacity {
    NumberAnimation {
      duration: Style.animationNormal
      easing.type: Easing.InOutQuad
    }
  }

  onDepthChanged: requestCutout()
  onShowingChanged: requestCutout()
  function requestCutout() {
    if (showing && depth)
      WallpaperCutoutService.request(wallpaper);
  }

  Timer {
    interval: 33
    repeat: true
    running: root.visible
    onTriggered: root.elapsed += interval / 1000
  }

  EdgeWaves {
    anchors.fill: parent
    values: WallpaperVisualizer.demoSpectrum(32, root.elapsed)
    prefs: root.prefs
    cutout: root.depth ? WallpaperCutoutService.cutoutFor(root.wallpaper) : ""
    devicePixelRatio: root.devicePixelRatio
  }
}
