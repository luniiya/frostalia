import QtQuick
import Quickshell
import qs.Commons
import qs.Services.Frostalia
import qs.Services.UI

// The widgets of one monitor, loaded from their saved data. Shared by the desktop window and by
// the Edit Desktop card, which is why `editing` is a property of the layer.
Item {
  id: root

  property ShellScreen screen
  // Saved widget data of this monitor (an entry of Settings.data.desktopWidgets.monitorWidgets)
  property var widgets: []
  // Whether the widgets of this layer can be moved, resized and removed
  property bool editing: false

  signal widgetAdded(Item item)
  signal widgetRemoved(Item item)

  // Alignment guides to draw while a widget is dragged: [{vertical, position}] in desktop pixels
  property var guides: []

  // The loaded widget items by their index in `widgets`
  property var items: ({})

  function itemAt(index) {
    return items[index] || null;
  }

  // Direct binding to registry's widgets property for reactivity
  readonly property var registeredWidgets: DesktopWidgetRegistry.widgets

  // Incremented when the plugin widget registry changes
  property int pluginReloadCounter: 0

  Connections {
    target: DesktopWidgetRegistry

    function onPluginWidgetRegistryUpdated() {
      root.pluginReloadCounter++;
    }
  }

  Repeater {
    model: root.widgets

    delegate: Loader {
      id: widgetLoader

      required property var modelData
      required property int index
      property Item _loadedItem: null
      readonly property bool _isPlugin: DesktopWidgetRegistry.isPluginWidget(modelData.id)

      // Bind to registeredWidgets and pluginReloadCounter to re-evaluate when plugins register/unregister
      active: (modelData.id in root.registeredWidgets) && (root.pluginReloadCounter >= 0)

      // All widgets use setSource() so that screen, widgetData, and
      // widgetIndex are set as initial properties, available during
      // Component.onCompleted. This prevents registration-key
      // mismatches in widgets that build IDs from screen.name.
      Component.onCompleted: _loadWidget()

      onActiveChanged: {
        if (active)
          _loadWidget();
      }

      function _loadWidget() {
        var widgetId = modelData.id;
        var comp = root.registeredWidgets[widgetId];
        if (!comp)
          return;

        var props = {
          "screen": root.screen,
          "widgetData": modelData,
          "widgetIndex": index
        };

        if (_isPlugin) {
          var pluginId = widgetId.replace("plugin:", "");
          var api = PluginService.getPluginAPI(pluginId);
          if (api)
            props.pluginApi = api;
          setSource(comp.url, props);
        } else {
          // Core widgets: use explicit URL (inline Component.url
          // returns the registry file, not the widget file)
          var url = DesktopWidgetRegistry.widgetUrls[widgetId];
          if (url)
            setSource(url, props);
        }
      }

      onLoaded: {
        if (!item)
          return;
        item.parent = root;
        if (item.editing !== undefined)
          item.editing = Qt.binding(() => root.editing);
        _loadedItem = item;
        var copy = Object.assign({}, root.items);
        copy[index] = item;
        root.items = copy;
        root.widgetAdded(item);
      }

      onItemChanged: {
        if (!item && _loadedItem) {
          var gone = _loadedItem;
          _loadedItem = null;
          var copy = Object.assign({}, root.items);
          if (copy[index] === gone)
            delete copy[index];
          root.items = copy;
          root.widgetRemoved(gone);
        }
      }
    }
  }

  // Guide lines of the snap in progress
  Repeater {
    model: root.guides

    delegate: Rectangle {
      required property var modelData
      color: ShellColors.mSecondary
      z: 10000
      x: modelData.vertical ? modelData.position - 1 : 0
      y: modelData.vertical ? 0 : modelData.position - 1
      width: modelData.vertical ? 2 : root.width
      height: modelData.vertical ? root.height : 2
    }
  }
}
