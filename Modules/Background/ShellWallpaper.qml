import QtQuick
import Quickshell
import qs.Services.UI

// The shell's own wallpaper, one WallpaperLayer per screen, while Settings > Wallpaper has
// the renderer on. Off, the system wallpaper daemon (awww) draws it and nothing is made here.
Variants {
  model: Quickshell.screens

  delegate: Loader {
    id: screenLoader
    required property ShellScreen modelData

    active: modelData && WallpaperService.rendererEnabled

    sourceComponent: WallpaperLayer {
      screen: screenLoader.modelData
    }
  }
}
