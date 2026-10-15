import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../../../Helpers/BubbleLogic.js" as BubbleLogic
import qs.Commons
import qs.Services.UI
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginL

  function revealSetting(labelKey) {
    return BubbleLogic.revealSetting(root, I18n.tr(labelKey));
  }

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("panels.bubbles.enabled-label")
    description: I18n.tr("panels.bubbles.enabled-description")
    checked: Settings.data.bubbles.enabled
    defaultValue: Settings.getDefaultValue("bubbles.enabled")
    onToggled: checked => Settings.data.bubbles.enabled = checked
  }

  NLabel {
    Layout.fillWidth: true
    visible: Settings.data.bubbles.configurations.length === 0
    description: I18n.tr("panels.bubbles.empty")
  }

  Repeater {
    model: Quickshell.screens

    delegate: ColumnLayout {
      id: monitorSection
      required property var modelData
      readonly property var bubbles: BubbleLogic.forMonitor(Settings.data.bubbles.configurations, modelData.name)
      Layout.fillWidth: true
      spacing: Style.marginM

      RowLayout {
        Layout.fillWidth: true
        NText {
          Layout.fillWidth: true
          text: monitorSection.modelData.name
          color: Color.mPrimary
          font.weight: Style.fontWeightBold
        }
        NButton {
          text: I18n.tr("panels.bubbles.add")
          icon: "add"
          onClicked: {
            var configurations = Settings.data.bubbles.configurations.slice();
            var id = "bubble-" + Date.now();
            while (configurations.some(function (bubble) {
              return bubble.id === id;
            }))
              id += "-1";
            configurations.push(Object.assign({}, BubbleService.defaults, {
                                                id: id,
                                                monitor: monitorSection.modelData.name,
                                                widgets: [
                                                  {
                                                    id: "Clock",
                                                    formatHorizontal: "HH:mm"
                                                  }
                                                ]
                                              }));
            Settings.data.bubbles.configurations = configurations;
            Settings.data.bubbles.enabled = true;
          }
        }
      }

      Repeater {
        model: monitorSection.bubbles.length
        delegate: BubbleEditor {
          required property int index
          Layout.fillWidth: true
          bubbleId: monitorSection.bubbles[index]?.id || ""
          bubbleScreen: monitorSection.modelData
          number: index + 1
        }
      }
    }
  }

  // Retain entries for unplugged monitors so their settings remain editable.
  Repeater {
    model: Settings.data.bubbles.configurations.filter(function (bubble) {
      return !Quickshell.screens.some(function (screen) {
        return screen.name === bubble.monitor;
      });
    })
    delegate: BubbleEditor {
      required property var modelData
      required property int index
      Layout.fillWidth: true
      bubbleId: modelData.id
      monitorName: modelData.monitor
      number: index + 1
    }
  }
}
