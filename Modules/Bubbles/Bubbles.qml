import QtQuick
import Quickshell
import "../../Helpers/BubbleLogic.js" as BubbleLogic
import qs.Commons

Variants {
  model: Quickshell.screens

  delegate: Item {
    id: screenItem
    required property ShellScreen modelData

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
