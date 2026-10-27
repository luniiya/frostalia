import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services.Compositor
import qs.Services.Frostalia
import qs.Services.Power
import qs.Services.UI
import qs.Widgets

Variants {
  id: root
  model: Quickshell.screens

  // Force reload counter - incremented when plugin widget registry changes
  property int pluginReloadCounter: 0

  Connections {
    target: DesktopWidgetRegistry

    function onPluginWidgetRegistryUpdated() {
      root.pluginReloadCounter++;
      Logger.d("DesktopWidgets", "Plugin widget registry updated, reload counter:", root.pluginReloadCounter);
    }
  }

  delegate: Loader {
    id: screenLoader
    required property ShellScreen modelData

    // Reactive property for widgets on this specific screen
    // Returns a fresh array whenever Settings changes
    property var screenWidgets: {
      if (!modelData || !modelData.name) {
        return [];
      }
      var monitorWidgets = Settings.data.desktopWidgets.monitorWidgets || [];
      for (var i = 0; i < monitorWidgets.length; i++) {
        if (monitorWidgets[i].name === modelData.name) {
          return monitorWidgets[i].widgets || [];
        }
      }
      return [];
    }

    // Only create PanelWindow if enabled AND (screen has widgets OR in edit mode)
    // During compositor overview, show widgets only when overviewEnabled is true.
    active: modelData && Settings.data.desktopWidgets.enabled && screenWidgets.length > 0 && (!CompositorService.overviewActive || Settings.data.desktopWidgets.overviewEnabled) && (!PowerProfileService.ecoMode || !Settings.data.ecoMode.disableDesktopWidgets)

    sourceComponent: PanelWindow {
      id: window
      color: "transparent"
      screen: screenLoader.modelData
      mask: widgetsMask

      // Dynamic mask: combine clickable regions for each loaded widget
      property var _maskRegions: []

      Component {
        id: maskRegionComponent
        Region {}
      }

      Region {
        id: widgetsMask
        regions: window._maskRegions
      }

      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      WlrLayershell.layer: WlrLayer.Bottom
      WlrLayershell.exclusionMode: ExclusionMode.Ignore
      WlrLayershell.namespace: "frostalia-desktop-widgets-" + (screen?.name || "unknown")

      anchors {
        top: true
        bottom: true
        right: true
        left: true
      }

      Component.onCompleted: {
        Logger.d("DesktopWidgets", "Created panel window for", screen?.name);
      }

      Item {
        id: widgetsContainer
        anchors.fill: parent

        // Load widgets dynamically from per-monitor array. They are edited on the Edit Desktop screen.
        DesktopWidgetsLayer {
          anchors.fill: parent
          screen: window.screen
          widgets: screenLoader.screenWidgets
          editing: false

          onWidgetAdded: item => {
            // Create mask region so this widget receives mouse input
            var region = maskRegionComponent.createObject(window);
            region.item = item;
            window._maskRegions = window._maskRegions.concat([region]);
          }

          onWidgetRemoved: item => {
            var gone = window._maskRegions.filter(r => r.item === item);
            window._maskRegions = window._maskRegions.filter(r => r.item !== item);
            gone.forEach(r => r.destroy());
          }
        }
      }
    }
  }
}
