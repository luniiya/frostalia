import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services.Media
import qs.Services.UI

// Audio waves along the screen edges, drawn right above the wallpaper: on the
// background layer, under desktop widgets and windows, and click-through. When the
// wallpaper has a clear subject, a cut-out of it is drawn over the waves so they
// pass behind it (see WallpaperCutoutService). With the shell's own wallpaper on, its
// window draws them (ScreenWaves) and none are made here.
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

    // The shell's own wallpaper draws the waves itself, inside its window: two windows on
    // the background layer stack in the order they map, which isn't ours to pick
    active: modelData && root.enabled && !WallpaperService.rendererEnabled

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

      ScreenWaves {
        anchors.fill: parent
        screenName: screenLoader.modelData?.name ?? ""
        devicePixelRatio: window.screen?.devicePixelRatio ?? 1
      }
    }
  }
}
