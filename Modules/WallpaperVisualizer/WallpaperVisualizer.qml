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
      readonly property var values: SpectrumService.values || []

      Item {
        id: scene
        anchors.fill: parent
        opacity: window.playing ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
          NumberAnimation {
            duration: 900
            easing.type: Easing.InOutQuad
          }
        }

        // Data texture: one pixel per spectrum band, R channel = amplitude
        Item {
          id: dataRow
          width: Math.max(window.values.length, 4)
          height: 1

          Repeater {
            model: dataRow.width
            Rectangle {
              required property int index
              x: index
              width: 1
              height: 1
              color: {
                const v = index < window.values.length ? window.values[index] : 0;
                return Qt.rgba(isFinite(v) ? Math.max(0, Math.min(1, v)) : 0, 0, 0, 1);
              }
            }
          }
        }

        ShaderEffectSource {
          id: dataTexture
          sourceItem: dataRow
          textureSize: Qt.size(dataRow.width, 1)
          live: true
          smooth: false
          hideSource: true
        }

        ShaderEffect {
          anchors.fill: parent
          visible: window.values.length >= 2
          opacity: WallpaperVisualizer.clamp(root.prefs.opacity, WallpaperVisualizer.opacityRange, 0.7)

          property variant dataSource: dataTexture
          property color fillColor: ShellColors.resolveColorKey(root.prefs.color)
          property real count: window.values.length
          property real texWidth: dataRow.width
          property vector4d edges: {
            const f = WallpaperVisualizer.edgeFlags(root.prefs.edges);
            return Qt.vector4d(f[0], f[1], f[2], f[3]);
          }
          property size size: Qt.size(width, height)
          property real waveHeight: height * WallpaperVisualizer.clamp(root.prefs.height, WallpaperVisualizer.heightRange, 0.25)

          fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/Shaders/qsb/edge_wave.frag.qsb")
          blending: true
        }

        // The wallpaper's subject, placed as the wallpaper daemon places the image
        // (scaled to cover the screen, centered), so it lines up exactly
        Image {
          anchors.fill: parent
          source: window.cutout ? "file://" + window.cutout : ""
          fillMode: Image.PreserveAspectCrop
          sourceSize: Qt.size(width * (window.screen?.devicePixelRatio ?? 1), height * (window.screen?.devicePixelRatio ?? 1))
          asynchronous: true
          cache: false
          smooth: true
          opacity: status === Image.Ready ? 1 : 0
          Behavior on opacity {
            NumberAnimation {
              duration: Style.animationNormal
            }
          }
        }
      }
    }
  }
}
