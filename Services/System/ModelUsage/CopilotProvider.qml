import QtQuick
import Quickshell
import Quickshell.Io
import "../../../Helpers/ModelUsageLogic.js" as ModelUsageLogic
import qs.Commons

// GitHub Copilot: quota from the Copilot API using the `gh` CLI token
ModelUsageProvider {
  id: root

  providerId: "copilot"
  providerName: "Copilot"
  helpText: I18n.tr("model-usage.help.copilot")
  hasLocalStats: false
  primary: ModelUsageLogic.emptyLimit("premium")
  secondary: ModelUsageLogic.emptyLimit("chat")

  property real lastRefreshAtMs: 0
  readonly property int refreshMinIntervalMs: 5 * 60 * 1000

  Process {
    id: tokenProcess
    command: ["gh", "auth", "token"]
    stdout: StdioCollector {
      onStreamFinished: {
        const token = text.trim();
        if (token)
          root.fetchUsage(token);
      }
    }
    onExited: code => {
      if (code !== 0) {
        root.statusText = I18n.tr("model-usage.status.not-authenticated");
        root.ready = false;
        root.clearLimits();
      }
    }
  }

  Timer {
    interval: root.refreshMinIntervalMs
    running: root.enabled
    repeat: true
    onTriggered: tokenProcess.running = true
  }

  onEnabledChanged: refresh()
  Component.onCompleted: refresh()

  function fetchUsage(token) {
    const xhr = new XMLHttpRequest();
    xhr.open("GET", "https://api.github.com/copilot_internal/user");
    xhr.setRequestHeader("Authorization", "token " + token);
    xhr.setRequestHeader("Accept", "application/json");
    xhr.onreadystatechange = function () {
      if (xhr.readyState !== XMLHttpRequest.DONE)
        return;
      if (xhr.status === 401 || xhr.status === 403) {
        root.statusText = I18n.tr("model-usage.status.token-invalid");
        root.tierLabel = "";
        root.ready = false;
        root.clearLimits();
        return;
      }
      if (xhr.status < 200 || xhr.status >= 300) {
        Logger.w("ModelUsage", "Copilot usage request failed, status", xhr.status);
        root.ready = false;
        root.clearLimits();
        return;
      }
      try {
        const usage = ModelUsageLogic.parseCopilotUsage(JSON.parse(xhr.responseText));
        root.tierLabel = usage.tier;
        root.primary = usage.primary;
        root.secondary = usage.secondary;
        root.statusText = "";
        root.ready = true;
      } catch (e) {
        Logger.w("ModelUsage", "Failed to parse Copilot usage:", e);
      }
    };
    xhr.send();
  }

  function refresh() {
    if (!enabled)
      return;
    const now = Date.now();
    if (lastRefreshAtMs > 0 && now - lastRefreshAtMs < refreshMinIntervalMs)
      return;
    lastRefreshAtMs = now;
    tokenProcess.running = true;
  }
}
