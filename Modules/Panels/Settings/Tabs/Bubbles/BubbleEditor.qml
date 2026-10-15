import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../../../../../Helpers/BubbleLogic.js" as BubbleLogic
import qs.Commons
import qs.Modules.Bubbles
import qs.Services.UI
import qs.Widgets

NBox {
  id: root
  required property string bubbleId
  property var bubbleScreen: null
  property string monitorName: bubbleScreen?.name || ""
  property int number: 1
  readonly property int monitorBubbleCount: BubbleLogic.forMonitor(Settings.data.bubbles.configurations, monitorName).length
  readonly property int monitorBubbleIndex: BubbleLogic.forMonitor(Settings.data.bubbles.configurations, monitorName).findIndex(function (bubble) {
    return bubble.id === root.bubbleId;
  })
  readonly property string section: BubbleLogic.sectionId(bubbleId)
  readonly property var bubble: Settings.getBubble(monitorName, section) || BubbleLogic.effective(null, BubbleService.defaults)
  readonly property bool vertical: BubbleLogic.isVertical(bubble.position)
  readonly property alias availableWidgets: widgetChoices

  BubbleWidgetChoices {
    id: widgetChoices
  }

  implicitHeight: content.implicitHeight + Style.margin2L

  function change(key, value) {
    var patch = {};
    patch[key] = value;
    Settings.updateBubble(monitorName, bubbleId, patch);
  }

  function refreshWidgets() {
    widgetChoices.widgetIds = BarWidgetRegistry.getAvailableWidgets();
  }

  Component.onCompleted: refreshWidgets()
  Connections {
    target: BarWidgetRegistry
    function onPluginWidgetRegistryUpdated() {
      root.refreshWidgets();
    }
  }

  NPluginSettingsPopup {
    id: pluginSettings
    parent: Overlay.overlay
  }

  ColumnLayout {
    id: content
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: Style.marginL
    spacing: Style.marginM

    RowLayout {
      Layout.fillWidth: true
      NText {
        Layout.fillWidth: true
        text: I18n.tr("panels.bubbles.bubble", {
                        number: root.number
                      }) + " · " + root.monitorName
        font.weight: Style.fontWeightBold
        color: Color.mPrimary
      }
      NIconButton {
        icon: root.vertical ? "arrow-up" : "arrow-left"
        tooltipText: I18n.tr("panels.bubbles.move-earlier")
        enabled: root.monitorBubbleIndex > 0
        onClicked: Settings.data.bubbles.configurations = BubbleLogic.moveBubble(Settings.data.bubbles.configurations, root.monitorName, root.bubbleId, -1)
      }
      NIconButton {
        icon: root.vertical ? "arrow-down" : "arrow-right"
        tooltipText: I18n.tr("panels.bubbles.move-later")
        enabled: root.monitorBubbleIndex >= 0 && root.monitorBubbleIndex < root.monitorBubbleCount - 1
        onClicked: Settings.data.bubbles.configurations = BubbleLogic.moveBubble(Settings.data.bubbles.configurations, root.monitorName, root.bubbleId, 1)
      }
      NIconButton {
        icon: "trash"
        tooltipText: I18n.tr("panels.bubbles.remove")
        onClicked: Settings.data.bubbles.configurations = Settings.data.bubbles.configurations.filter(function (bubble) {
          return bubble.id !== root.bubbleId || bubble.monitor !== root.monitorName;
        })
      }
    }

    NSectionEditor {
      Layout.fillWidth: true
      sectionName: I18n.tr("panels.bubbles.widgets")
      sectionId: root.section
      widgetRegistry: BarWidgetRegistry
      widgetModel: root.bubble.widgets
      availableWidgets: root.availableWidgets
      availableSections: [root.section]
      settingsDialogComponent: Quickshell.shellDir + "/Modules/Panels/Settings/Bar/BarWidgetSettingsDialog.qml"
      screen: root.bubbleScreen
      barIsVertical: root.vertical
      onAddWidget: (widgetId, section) => {
        var widgets = root.bubble.widgets.slice();
        widgets.push(Object.assign({
                                     id: widgetId
                                   }, BarWidgetRegistry.widgetMetadata[widgetId] || {}));
        root.change("widgets", widgets);
      }
      onRemoveWidget: (section, index) => {
        var widgets = root.bubble.widgets.slice();
        widgets.splice(index, 1);
        root.change("widgets", widgets);
      }
      onReorderWidget: (section, fromIndex, toIndex) => root.change("widgets", BubbleLogic.reorder(root.bubble.widgets, fromIndex, toIndex))
      onUpdateWidgetSettings: (section, index, settings) => Settings.updateBubbleWidget(root.monitorName, section, index, settings)
      onOpenPluginSettingsRequested: (manifest, entryPoint) => pluginSettings.openPluginSettings(manifest, entryPoint)
    }

    NLabel {
      Layout.fillWidth: true
      description: I18n.tr("panels.bubbles.widgets-description")
    }
    NLabel {
      Layout.fillWidth: true
      description: I18n.tr("panels.bubbles.widget-order-description")
    }

    NCollapsible {
      id: bubbleSettings
      label: I18n.tr("panels.bubbles.settings-label")
      description: I18n.tr("panels.bubbles.settings-description")
      NComboBox {
        Layout.fillWidth: true
        label: I18n.tr("panels.bubbles.monitor-label")
        description: I18n.tr("panels.bubbles.monitor-description")
        model: Quickshell.screens.map(function (screen) {
          return {
            key: screen.name,
            name: screen.name
          };
        })
        currentKey: root.monitorName
        onSelected: key => root.change("monitor", key)
      }

      NComboBox {
        Layout.fillWidth: true
        label: I18n.tr("panels.bubbles.position-label")
        description: I18n.tr("panels.bubbles.position-description")
        model: [
          {
            key: "top",
            name: I18n.tr("positions.top")
          },
          {
            key: "bottom",
            name: I18n.tr("positions.bottom")
          },
          {
            key: "left",
            name: I18n.tr("positions.left")
          },
          {
            key: "right",
            name: I18n.tr("positions.right")
          }
        ]
        currentKey: root.bubble.position
        defaultValue: Settings.getDefaultValue("bubbles.defaults.position")
        onSelected: key => root.change("position", key)
      }

      NComboBox {
        Layout.fillWidth: true
        label: I18n.tr("panels.bubbles.alignment-label")
        description: I18n.tr("panels.bubbles.alignment-description")
        model: [
          {
            key: "start",
            name: I18n.tr("panels.bubbles.start")
          },
          {
            key: "center",
            name: I18n.tr("panels.bubbles.center")
          },
          {
            key: "end",
            name: I18n.tr("panels.bubbles.end")
          }
        ]
        currentKey: root.bubble.alignment
        defaultValue: Settings.getDefaultValue("bubbles.defaults.alignment")
        onSelected: key => root.change("alignment", key)
      }

      NComboBox {
        Layout.fillWidth: true
        label: I18n.tr("panels.bubbles.style-label")
        description: I18n.tr("panels.bubbles.style-description")
        model: [
          {
            key: "floating",
            name: I18n.tr("panels.bubbles.floating")
          },
          {
            key: "attached",
            name: I18n.tr("panels.bubbles.attached")
          },
          {
            key: "notch",
            name: I18n.tr("panels.bubbles.notch")
          }
        ]
        currentKey: root.bubble.style
        defaultValue: Settings.getDefaultValue("bubbles.defaults.style")
        onSelected: key => root.change("style", key)
      }

      NValueSlider {
        label: I18n.tr("panels.bubbles.height-label")
        description: I18n.tr("panels.bubbles.height-description")
        from: 20
        to: 100
        stepSize: 1
        value: root.bubble.height
        text: Math.round(value) + " px"
        defaultValue: Settings.getDefaultValue("bubbles.defaults.height")
        onMoved: value => root.change("height", value)
      }

      NValueSlider {
        label: I18n.tr("panels.bubbles.padding-label")
        description: I18n.tr("panels.bubbles.padding-description")
        from: 0
        to: 30
        stepSize: 1
        value: root.bubble.padding
        text: Math.round(value) + " px"
        defaultValue: Settings.getDefaultValue("bubbles.defaults.padding")
        onMoved: value => root.change("padding", value)
      }

      NValueSlider {
        label: I18n.tr("panels.bubbles.margin-label")
        description: I18n.tr("panels.bubbles.margin-description")
        from: 0
        to: 100
        stepSize: 1
        value: root.bubble.margin
        text: Math.round(value) + " px"
        defaultValue: Settings.getDefaultValue("bubbles.defaults.margin")
        onMoved: value => root.change("margin", value)
      }

      NValueSlider {
        label: I18n.tr("panels.bubbles.offset-label")
        description: I18n.tr("panels.bubbles.offset-description")
        from: -1000
        to: 1000
        stepSize: 1
        value: root.bubble.offset
        text: Math.round(value) + " px"
        defaultValue: Settings.getDefaultValue("bubbles.defaults.offset")
        onMoved: value => root.change("offset", value)
      }

      NValueSlider {
        label: I18n.tr("panels.bubbles.spacing-label")
        description: I18n.tr("panels.bubbles.spacing-description")
        from: 0
        to: 50
        stepSize: 1
        value: root.bubble.spacing
        text: Math.round(value) + " px"
        defaultValue: Settings.getDefaultValue("bubbles.defaults.spacing")
        onMoved: value => root.change("spacing", value)
      }

      NValueSlider {
        label: I18n.tr("panels.bubbles.radius-label")
        description: I18n.tr("panels.bubbles.radius-description")
        from: 0
        to: 50
        stepSize: 1
        value: root.bubble.radius
        text: Math.round(value) + " px"
        defaultValue: Settings.getDefaultValue("bubbles.defaults.radius")
        onMoved: value => root.change("radius", value)
      }

      NColorChoice {
        Layout.fillWidth: true
        enabled: !root.bubble.oledMode
        label: I18n.tr("panels.bubbles.background-color-label")
        description: I18n.tr("panels.bubbles.background-color-description")
        noneColor: Color.mSurface
        noneOnColor: Color.mOnSurface
        currentKey: root.bubble.backgroundColorKey
        defaultValue: Settings.getDefaultValue("bubbles.defaults.backgroundColorKey")
        onSelected: key => root.change("backgroundColorKey", key)
      }

      NValueSlider {
        label: I18n.tr("panels.bubbles.opacity-label")
        description: I18n.tr("panels.bubbles.opacity-description")
        enabled: !root.bubble.oledMode
        from: 0
        to: 1
        stepSize: 0.01
        value: root.bubble.opacity
        text: Math.round(value * 100) + " %"
        defaultValue: Settings.getDefaultValue("bubbles.defaults.opacity")
        onMoved: value => root.change("opacity", value)
      }

      NToggle {
        Layout.fillWidth: true
        label: I18n.tr("panels.bubbles.oled-mode-label")
        description: I18n.tr("panels.bubbles.oled-mode-description")
        checked: root.bubble.oledMode
        defaultValue: Settings.getDefaultValue("bubbles.defaults.oledMode")
        onToggled: checked => root.change("oledMode", checked)
      }

      NToggle {
        Layout.fillWidth: true
        label: I18n.tr("panels.bubbles.hide-fullscreen-label")
        description: I18n.tr("panels.bubbles.hide-fullscreen-description")
        checked: root.bubble.hideOnFullscreen
        defaultValue: Settings.getDefaultValue("bubbles.defaults.hideOnFullscreen")
        onToggled: checked => root.change("hideOnFullscreen", checked)
      }

      NToggle {
        Layout.fillWidth: true
        label: I18n.tr("panels.bubbles.auto-cycle-label")
        description: I18n.tr("panels.bubbles.auto-cycle-description")
        checked: root.bubble.autoCycle
        defaultValue: Settings.getDefaultValue("bubbles.defaults.autoCycle")
        onToggled: checked => root.change("autoCycle", checked)
      }

      NValueSlider {
        label: I18n.tr("panels.bubbles.cycle-interval-label")
        description: I18n.tr("panels.bubbles.cycle-interval-description")
        enabled: root.bubble.autoCycle
        from: 1
        to: 60
        stepSize: 1
        value: root.bubble.cycleInterval
        text: Math.round(value) + " s"
        defaultValue: Settings.getDefaultValue("bubbles.defaults.cycleInterval")
        onMoved: value => root.change("cycleInterval", value)
      }

      NComboBox {
        Layout.fillWidth: true
        label: I18n.tr("panels.bubbles.transition-label")
        description: I18n.tr("panels.bubbles.transition-description")
        model: [
          {
            key: "up",
            name: I18n.tr("panels.bubbles.transition-up")
          },
          {
            key: "down",
            name: I18n.tr("panels.bubbles.transition-down")
          },
          {
            key: "left",
            name: I18n.tr("panels.bubbles.transition-left")
          },
          {
            key: "right",
            name: I18n.tr("panels.bubbles.transition-right")
          },
          {
            key: "fade",
            name: I18n.tr("panels.bubbles.transition-fade")
          },
          {
            key: "none",
            name: I18n.tr("panels.bubbles.transition-none")
          }
        ]
        currentKey: root.bubble.transition
        defaultValue: Settings.getDefaultValue("bubbles.defaults.transition")
        onSelected: key => root.change("transition", key)
      }

      NValueSlider {
        label: I18n.tr("panels.bubbles.transition-duration-label")
        description: I18n.tr("panels.bubbles.transition-duration-description")
        enabled: root.bubble.transition !== "none"
        from: 0
        to: 1000
        stepSize: 10
        value: root.bubble.transitionDuration
        text: Math.round(value) + " ms"
        defaultValue: Settings.getDefaultValue("bubbles.defaults.transitionDuration")
        onMoved: value => root.change("transitionDuration", value)
      }
    }
  }
}
