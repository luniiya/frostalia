import QtQuick
import Quickshell
import "../../Helpers/WallpaperVisualizer.js" as WallpaperVisualizer
import qs.Commons
import qs.Services.Media
import qs.Services.Power
import qs.Services.UI

// One screen's audio waves, with the cut-out of the wallpaper's subject over them. Drawn
// in the visualizer's own window over the wallpaper daemon's, or inside the shell's
// wallpaper window (Modules/Background/WallpaperLayer.qml) when that draws it.
// WallpaperVisualizer registers with SpectrumService for both.
Item {
  id: root

  required property string screenName
  property real devicePixelRatio: 1

  readonly property var prefs: Settings.data.wallpaperVisualizer
  readonly property string wallpaper: WallpaperService.getWallpaper(screenName)
  readonly property bool playing: WallpaperVisualizer.wavesActive(prefs.enabled, SpectrumService.isIdle, PowerProfileService.ecoMode)
  readonly property string cutout: prefs.depth ? WallpaperCutoutService.cutoutFor(wallpaper) : ""

  // Ask for the cut-out as soon as a wallpaper shows, so it is ready when music starts
  onWallpaperChanged: requestCutout()
  Component.onCompleted: requestCutout()
  function requestCutout() {
    if (prefs.depth)
      WallpaperCutoutService.request(wallpaper);
  }
  Connections {
    target: root.prefs
    function onDepthChanged() {
      root.requestCutout();
    }
  }

  EdgeWaves {
    anchors.fill: parent
    opacity: root.playing ? 1 : 0
    visible: opacity > 0
    values: SpectrumService.values || []
    prefs: root.prefs
    cutout: root.cutout
    devicePixelRatio: root.devicePixelRatio

    Behavior on opacity {
      NumberAnimation {
        duration: 900
        easing.type: Easing.InOutQuad
      }
    }
  }
}
