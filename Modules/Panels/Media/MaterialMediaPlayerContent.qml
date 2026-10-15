import QtQuick
import qs.Commons
import qs.Modules.Cards

MaterialMediaCard {
  required property var panel
  expanded: !panel.compactMode
  showAlbumArt: panel.showAlbumArt
  showVisualizer: panel.showVisualizer && panel.isPanelOpen
  spectrumId: "material-media-panel"
  implicitWidth: Math.round(440 * Style.uiScaleRatio)
  // Spectrum registration is owned by MaterialMediaCard.
  readonly property bool managesSpectrum: true
}
