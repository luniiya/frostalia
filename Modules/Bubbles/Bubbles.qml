import QtQuick
import Quickshell
import "../../Helpers/BubbleLogic.js" as BubbleLogic
import qs.Commons
import qs.Services.UI

Variants {
  model: Quickshell.screens

  delegate: Item {
    id: screenItem
    required property ShellScreen modelData

    readonly property var reserved: BubbleLogic.reservedEdges(Settings.data.bubbles.enabled, Settings.data.bubbles.configurations, BubbleService.defaults, BubbleService.sizes, modelData.name, modelData.width, modelData.height)

    Variants {
      model: ["top", "bottom", "left", "right"]

      delegate: BubbleExclusionZone {
        required property string modelData
        edge: modelData
        size: screenItem.reserved[modelData]
        screen: screenItem.modelData
      }
    }

    Variants {
      model: BubbleLogic.forMonitor(Settings.data.bubbles.configurations, screenItem.modelData.name).map(function (bubble) {
        return bubble.id;
      })

      delegate: BubbleWindow {
        required property string modelData
        bubbleId: modelData
        screen: screenItem.modelData
      }
    }
  }
}
