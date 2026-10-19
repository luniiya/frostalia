import QtQuick
import qs.Commons
import qs.Modules.MainScreen

SmartPanel {
  id: root

  preferredWidth: Math.round(420 * Style.uiScaleRatio)
  preferredHeight: Math.round(620 * Style.uiScaleRatio)

  // Opens straight on a page, e.g. openPage("messages").
  function openPage(page, buttonItem) {
    pendingPage = page;
    open(buttonItem);
  }
  property string pendingPage: ""

  panelContent: KdeConnectContent {
    panel: root
    property real contentPreferredWidth: root.preferredWidth
    property real contentPreferredHeight: isHome ? Math.min(root.preferredHeight, homeHeight) : root.preferredHeight
  }
}
