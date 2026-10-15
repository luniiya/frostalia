import QtQuick
import Quickshell
import Quickshell.Io
import "../../../Helpers/ModelUsageLogic.js" as ModelUsageLogic
import qs.Commons

// Gemini CLI: today's session files under ~/.gemini/tmp
ModelUsageProvider {
  id: root

  providerId: "gemini"
  providerName: "Gemini"
  helpText: I18n.tr("model-usage.help.gemini")

  // Prints the number of today's session files, then their concatenated content
  Process {
    id: sessionReader
    command: ["sh", "-c", "dir=\"$1\"; pattern=\"session-$(date +%Y-%m-%d)*.jsonl\"; find \"$dir\" -type f -name \"$pattern\" | wc -l; find \"$dir\" -type f -name \"$pattern\" -exec cat {} +", "sh", root.resolvePath("~/.gemini/tmp")]
    stdout: StdioCollector {
      onStreamFinished: {
        const out = text || "";
        const newline = out.indexOf("\n");
        root.todaySessions = parseInt(newline >= 0 ? out.substring(0, newline) : out) || 0;
        const s = ModelUsageLogic.parseGeminiSessions(newline >= 0 ? out.substring(newline + 1) : "");
        root.todayPrompts = s.prompts;
        root.todayTotalTokens = s.tokens;
        root.todayTokensByModel = s.tokensByModel;
        root.ready = true;
      }
    }
  }

  Timer {
    interval: 60 * 1000
    running: root.enabled
    repeat: true
    onTriggered: root.refresh()
  }

  onEnabledChanged: refresh()
  Component.onCompleted: refresh()

  function refresh() {
    if (enabled)
      sessionReader.running = true;
  }
}
