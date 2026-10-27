import QtQuick
import Quickshell
import "../../Helpers/WallpaperVisualizer.js" as WallpaperVisualizer
import qs.Commons

// The waves themselves, sized to a screen: spectrum `values` as waves along the edges
// picked in `prefs` (Settings.data.wallpaperVisualizer), with the wallpaper's subject
// cut-out drawn over them. Used by the wallpaper visualizer and the Edit Desktop preview.
Item {
  id: root

  property var values: []
  property var prefs: ({})
  // Cut-out image path, or ""
  property string cutout: ""
  property real devicePixelRatio: 1

  readonly property var look: WallpaperVisualizer.look(prefs)

  // Data texture: one pixel per spectrum band, R channel = amplitude
  Item {
    id: dataRow
    width: Math.max(root.values.length, 4)
    height: 1

    Repeater {
      model: dataRow.width
      Rectangle {
        required property int index
        x: index
        width: 1
        height: 1
        color: {
          const v = index < root.values.length ? root.values[index] : 0;
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
    visible: root.values.length >= 2
    opacity: WallpaperVisualizer.clamp(root.prefs.opacity, WallpaperVisualizer.opacityRange, 0.7)

    property variant dataSource: dataTexture
    property color fillColor: ShellColors.resolveColorKey(root.prefs.color)
    property real count: root.values.length
    property real texWidth: dataRow.width
    property vector4d edges: {
      const f = WallpaperVisualizer.edgeFlags(root.prefs.edges);
      return Qt.vector4d(f[0], f[1], f[2], f[3]);
    }
    property size size: Qt.size(width, height)
    property real waveHeight: height * WallpaperVisualizer.clamp(root.prefs.height, WallpaperVisualizer.heightRange, 0.25)
    property real whiteness: root.look.whiteness
    property real rim: root.look.rim
    property real backWave: root.look.backWave
    property real softness: root.look.softness

    fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/Shaders/qsb/edge_wave.frag.qsb")
    blending: true
  }

  // The wallpaper's subject, placed as the wallpaper daemon places the image
  // (scaled to cover the screen, centered), so it lines up exactly
  Image {
    anchors.fill: parent
    source: root.cutout ? "file://" + root.cutout : ""
    fillMode: Image.PreserveAspectCrop
    sourceSize: Qt.size(width * root.devicePixelRatio, height * root.devicePixelRatio)
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
