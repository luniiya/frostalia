import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Modules.MainScreen
import qs.Services.Media
import qs.Services.UI
import qs.Widgets
import qs.Widgets.AudioSpectrum

SmartPanel {
  id: root

  preferredWidth: Math.round(360 * Style.uiScaleRatio)
  // Fallback only; SmartPanel uses panelContent.contentPreferredHeight when set.
  preferredHeight: Math.round((root.compactMode ? 240 : 400) * Style.uiScaleRatio)

  property var mediaMiniSettings: {
    const widget = BarService.lookupWidget("MediaMini", screen?.name);
    return widget ? widget.widgetSettings : null;
  }

  function refreshMediaMiniSettings() {
    const widget = BarService.lookupWidget("MediaMini", screen?.name);
    root.mediaMiniSettings = widget ? widget.widgetSettings : null;
  }

  Connections {
    target: BarService
    function onActiveWidgetsChanged() {
      root.refreshMediaMiniSettings();
    }
  }

  Connections {
    target: Settings
    function onSettingsSaved() {
      root.refreshMediaMiniSettings();
    }
  }

  readonly property string visualizerType: (mediaMiniSettings && mediaMiniSettings.visualizerType !== undefined) ? mediaMiniSettings.visualizerType : "linear"
  readonly property bool showArtistFirst: !!(mediaMiniSettings && mediaMiniSettings.showArtistFirst !== undefined ? mediaMiniSettings.showArtistFirst : true)
  readonly property bool showAlbumArt: !!(mediaMiniSettings && mediaMiniSettings.panelShowAlbumArt !== undefined ? mediaMiniSettings.panelShowAlbumArt : true)
  readonly property bool showVisualizer: !!(mediaMiniSettings && mediaMiniSettings.showVisualizer !== undefined ? mediaMiniSettings.showVisualizer : true)
  readonly property bool compactMode: !!(mediaMiniSettings && mediaMiniSettings.compactMode !== undefined ? mediaMiniSettings.compactMode : false)
  readonly property string scrollingMode: (mediaMiniSettings && mediaMiniSettings.scrollingMode !== undefined) ? mediaMiniSettings.scrollingMode : "hover"

  readonly property bool isSideBySide: root.compactMode && root.showAlbumArt

  property bool needsSpectrum: false

  onNeedsSpectrumChanged: {
    if (root.needsSpectrum) {
      SpectrumService.registerComponent("mediaplayerpanel");
    } else {
      SpectrumService.unregisterComponent("mediaplayerpanel");
    }
  }

  Component.onCompleted: {
    if (root.needsSpectrum) {
      SpectrumService.registerComponent("mediaplayerpanel");
    }
  }

  Component.onDestruction: {
    SpectrumService.unregisterComponent("mediaplayerpanel");
  }

  panelContent: Item {
    property real contentPreferredWidth: mediaView.item?.implicitWidth || root.preferredWidth
    Binding {
      target: root
      property: "needsSpectrum"
      value: !mediaView.item?.managesSpectrum && (mediaView.item?.needsSpectrum || false)
    }
    property real contentPreferredHeight: mediaView.item?.implicitHeight || root.preferredHeight
    NStyleView {
      id: mediaView
      anchors.fill: parent
      surface: "mediaPlayer"
      viewProperties: ({
                         panel: root
                       })
    }
  }
}
