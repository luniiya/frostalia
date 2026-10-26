import QtQuick
import QtQuick.Controls
import Quickshell

import qs.Commons
import qs.Modules.MainScreen
import qs.Services.UI
import qs.Widgets
import "../../../Helpers/LauncherView.js" as LauncherView

SmartPanel {
  id: root

  // Disable when overlay mode is enabled (LauncherOverlayWindow handles it)
  enabled: !Settings.data.appLauncher.overviewLayer
  visible: !Settings.data.appLauncher.overviewLayer

  // Reference to core (set after panelContent loads)
  property var launcherCoreRef: null

  // Expose core launcher for external access (e.g., IPC)
  readonly property string searchText: launcherCoreRef ? launcherCoreRef.searchText : ""
  readonly property int selectedIndex: launcherCoreRef ? launcherCoreRef.selectedIndex : 0
  readonly property var results: launcherCoreRef ? launcherCoreRef.results : []
  readonly property var activeProvider: launcherCoreRef ? launcherCoreRef.activeProvider : null
  readonly property var currentProvider: launcherCoreRef ? launcherCoreRef.currentProvider : null
  readonly property bool isGridView: launcherCoreRef ? launcherCoreRef.isGridView : false
  readonly property int gridColumns: launcherCoreRef ? launcherCoreRef.gridColumns : 5

  function setSearchText(text) {
    if (launcherCoreRef)
      launcherCoreRef.setSearchText(text);
  }

  // Preview panel support
  readonly property bool previewActive: {
    if (!launcherCoreRef)
      return false;
    var provider = launcherCoreRef.activeProvider;
    if (!provider || !provider.hasPreview)
      return false;
    if (!Settings.data.appLauncher.enableClipPreview)
      return false;
    return selectedIndex >= 0 && results && !!results[selectedIndex];
  }
  readonly property int previewPanelWidth: Math.round(400 * Style.uiScaleRatio)

  // Panel sizing
  readonly property var panelSize: LauncherView.panelSize(Style.uiScaleRatio)

  preferredWidth: panelSize.width
  preferredHeight: panelSize.height

  // Positioning
  readonly property string screenBarPosition: Settings.getBarPositionForScreen(screen?.name)
  readonly property string panelPosition: {
    if (Settings.data.appLauncher.position === "follow_bar") {
      if (screenBarPosition === "left" || screenBarPosition === "right") {
        return `center_${screenBarPosition}`;
      } else {
        return `${screenBarPosition}_center`;
      }
    } else {
      return Settings.data.appLauncher.position;
    }
  }
  panelAnchorHorizontalCenter: !root.useButtonPosition && (panelPosition === "center" || panelPosition.endsWith("_center"))
  panelAnchorVerticalCenter: !root.useButtonPosition && panelPosition === "center"
  panelAnchorLeft: !root.useButtonPosition && panelPosition !== "center" && panelPosition.endsWith("_left")
  panelAnchorRight: !root.useButtonPosition && panelPosition !== "center" && panelPosition.endsWith("_right")
  panelAnchorBottom: !root.useButtonPosition && panelPosition.startsWith("bottom_")
  panelAnchorTop: !root.useButtonPosition && panelPosition.startsWith("top_")

  panelContent: Rectangle {
    id: ui
    color: "transparent"
    opacity: launcherCore.resultsReady ? 1.0 : 0.0

    Component.onCompleted: root.launcherCoreRef = launcherCore

    Behavior on opacity {
      NumberAnimation {
        duration: Style.animationFast
        easing.type: Easing.OutCirc
      }
    }

    // Preview Panel (external) - uses provider's preview component
    NDropShadow {
      source: previewBox
      anchors.fill: previewBox
      autoPaddingEnabled: true
      visible: previewBox.visible
      z: previewBox.z - 1
    }

    NBox {
      id: previewBox
      visible: root.previewActive
      width: root.previewPanelWidth
      height: Math.round(400 * Style.uiScaleRatio)
      forceOpaque: true // no blur for now
      x: root.panelAnchorRight ? -(root.previewPanelWidth + Style.marginM) : ui.width + Style.marginM
      y: {
        // Re-evaluate when the selection moves or the results scroll
        launcherCore.selectedIndex;
        launcherCore.resultsView?.contentY;
        var top = launcherCore.selectedRowTop(ui);
        return LauncherView.previewY(top === null ? Style.marginL : top, 0, ui.height, previewBox.height, Style.marginL);
      }
      z: -1

      opacity: visible ? 1.0 : 0.0
      Behavior on opacity {
        NumberAnimation {
          duration: Style.animationFast
        }
      }
      Behavior on y {
        NumberAnimation {
          duration: Style.animationFast
          easing.type: Easing.OutCubic
        }
      }

      Loader {
        id: previewLoader
        anchors.fill: parent
        active: root.previewActive
        source: {
          if (!active)
            return "";
          var provider = launcherCore.activeProvider;
          if (provider && provider.previewComponentPath)
            return provider.previewComponentPath;
          return "";
        }

        onLoaded: updatePreviewItem()
        onItemChanged: updatePreviewItem()

        function updatePreviewItem() {
          if (!item || launcherCore.selectedIndex < 0 || !launcherCore.results[launcherCore.selectedIndex])
            return;
          var provider = launcherCore.activeProvider;
          if (provider && provider.getPreviewData) {
            item.currentItem = provider.getPreviewData(launcherCore.results[launcherCore.selectedIndex]);
          } else {
            item.currentItem = launcherCore.results[launcherCore.selectedIndex];
          }
        }
      }
    }

    // Core launcher (state, providers, UI)
    LauncherCore {
      id: launcherCore
      anchors.fill: parent
      screen: root.screen
      isOpen: root.isPanelOpen
      onRequestClose: root.close()
      // Defer so the signal emission completes before SmartPanel
      // sets isPanelOpen=false and the contentLoader destroys us.
      onRequestCloseImmediately: Qt.callLater(root.closeImmediately)
    }

    // Update preview when selection changes
    Connections {
      target: launcherCore
      function onSelectedIndexChanged() {
        if (previewLoader.item)
          previewLoader.updatePreviewItem();
      }
    }
  }
}
