import QtQuick
import Quickshell
import "../../../Helpers/ModelUsageLogic.js" as ModelUsageLogic
import qs.Commons

// Common state of an AI usage provider. Providers fill these from local files
// or APIs; the bar widget and panel only read them.
Item {
  id: root
  visible: false

  property string providerId: ""
  property string providerName: ""
  property string providerIcon: "ai"
  property bool ready: false

  // Shown instead of the usage when something is wrong (translated)
  property string statusText: ""
  // Hint shown under statusText in the panel (translated)
  property string helpText: ""
  property string tierLabel: ""
  // Whether the provider reports today's prompts/sessions
  property bool hasLocalStats: true

  // Rate limits, see Helpers/ModelUsageLogic.js
  property var primary: ModelUsageLogic.emptyLimit("")
  property var secondary: ModelUsageLogic.emptyLimit("")

  property int todayPrompts: 0
  property int todaySessions: 0
  property real todayTotalTokens: 0
  property var todayTokensByModel: ({})
  property var recentDays: []
  property real totalPrompts: 0
  property int totalSessions: 0
  property var modelUsage: ({})

  function refresh() {
  }

  function clearLimits() {
    primary = ModelUsageLogic.emptyLimit(primary.kind);
    secondary = ModelUsageLogic.emptyLimit(secondary.kind);
  }

  function resolvePath(p) {
    if (p && p.startsWith("~"))
      return Quickshell.env("HOME") + p.substring(1);
    return p;
  }
}
