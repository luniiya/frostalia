import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../Helpers/WallpaperVisualizer.js" as WallpaperVisualizer
import qs.Commons
import qs.Services.Media
import qs.Services.Power
import qs.Services.UI

// Audio waves along the screen edges, drawn right above the wallpaper: on the
// background layer, under desktop widgets and windows, and click-through. When the
// wallpaper has a clear subject, a cut-out of it is drawn over the waves so they
// pass behind it (see WallpaperCutoutService).
Variants {
  id: root
  model: Quickshell.screens

  readonly property var prefs: Settings.data.wallpaperVisualizer
  readonly property bool enabled: prefs.enabled
  readonly property string spectrumId: "wallpaper-visualizer"

  onEnabledChanged: enabled ? SpectrumService.registerComponent(spectrumId) : SpectrumService.unregisterComponent(spectrumId)
  Component.onCompleted: {
    if (enabled)
      SpectrumService.registerComponent(spectrumId);
  }
  Component.onDestruction: SpectrumService.unregisterComponent(spectrumId)

  delegate: Loader {
    id: screenLoader
    required property ShellScreen modelData

    readonly property string wallpaper: WallpaperService.getWallpaper(modelData?.name ?? "")

    active: modelData && root.enabled

    // Ask for the cut-out as soon as a wallpaper shows, so it is ready when music starts
    onWallpaperChanged: requestCutout()
    onActiveChanged: requestCutout()
    function requestCutout() {
      if (active && root.prefs.depth)
        WallpaperCutoutService.request(wallpaper);
    }
    Connections {
      target: root.prefs
      function onDepthChanged() {
        screenLoader.requestCutout();
      }
    }

    sourceComponent: PanelWindow {
      id: window
      screen: screenLoader.modelData
      color: "transparent"
      // Nothing here takes input
      mask: Region {}

      WlrLayershell.layer: WlrLayer.Background
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      WlrLayershell.exclusionMode: ExclusionMode.Ignore
      WlrLayershell.namespace: "frostalia-wallpaper-visualizer-" + (screen?.name || "unknown")

      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }

      readonly property bool playing: WallpaperVisualizer.wavesActive(root.enabled, SpectrumService.isIdle, PowerProfileService.ecoMode)
      readonly property string cutout: root.prefs.depth ? WallpaperCutoutService.cutoutFor(screenLoader.wallpaper) : ""
      EdgeWaves {
        anchors.fill: parent
        opacity: window.playing ? 1 : 0
        visible: opacity > 0
        values: SpectrumService.values || []
        prefs: root.prefs
        cutout: window.cutout
        devicePixelRatio: window.screen?.devicePixelRatio ?? 1

        Behavior on opacity {
          NumberAnimation {
            duration: 900
            easing.type: Easing.InOutQuad
          }
        }
      }
    }
  }
}
