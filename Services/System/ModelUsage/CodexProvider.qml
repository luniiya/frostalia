import QtQuick
import Quickshell
import Quickshell.Io
import "../../../Helpers/ModelUsageLogic.js" as ModelUsageLogic
import qs.Commons

// Codex CLI: ~/.codex history, config, auth and the newest session files
ModelUsageProvider {
  id: root

  providerId: "codex"
  providerName: "Codex"
  helpText: I18n.tr("model-usage.help.codex")
  primary: ModelUsageLogic.emptyLimit("weekly")

  property string configModel: ""
  // Newest session files, oldest first; searched backwards for a token_count event
  property var sessionPaths: []
  property int sessionIndex: -1

  FileView {
    id: historyFile
    path: root.enabled ? root.resolvePath("~/.codex/history.jsonl") : ""
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      const h = ModelUsageLogic.countTodayHistory(text(), ModelUsageLogic.startOfDayMs(new Date()), "ts", 0.001, "session_id");
      root.todayPrompts = h.prompts;
      root.todaySessions = h.sessions;
      root.ready = true;
    }
  }

  FileView {
    id: configFile
    path: root.enabled ? root.resolvePath("~/.codex/config.toml") : ""
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.configModel = ModelUsageLogic.codexConfigModel(text())
  }

  FileView {
    id: authFile
    path: root.enabled ? root.resolvePath("~/.codex/auth.json") : ""
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      try {
        root.tierLabel = JSON.parse(text()).auth_mode || "";
      } catch (e) {
        Logger.w("ModelUsage", "Failed to parse Codex auth.json:", e);
      }
    }
  }

  FileView {
    id: sessionFile
    path: (root.sessionIndex >= 0 && root.sessionIndex < root.sessionPaths.length) ? root.sessionPaths[root.sessionIndex] : ""
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.applySession(text())
    onLoadFailed: root.tryPreviousSession()
  }

  Process {
    id: sessionLister
    command: ["find", root.resolvePath("~/.codex/sessions"), "-type", "f", "-name", "*.jsonl"]
    stdout: StdioCollector {
      onStreamFinished: {
        const files = text.trim().split("\n").filter(f => f.endsWith(".jsonl")).sort();
        root.sessionPaths = files.slice(Math.max(0, files.length - 16));
        root.sessionIndex = root.sessionPaths.length - 1;
      }
    }
  }

  Timer {
    interval: 60 * 1000
    running: root.enabled
    repeat: true
    onTriggered: sessionLister.running = true
  }

  onEnabledChanged: {
    if (enabled)
      sessionLister.running = true;
  }

  Component.onCompleted: {
    if (enabled)
      sessionLister.running = true;
  }

  function applySession(content) {
    const tokenCount = ModelUsageLogic.codexLastTokenCount(content);
    if (!tokenCount) {
      tryPreviousSession();
      return;
    }
    const usage = ModelUsageLogic.codexUsage(tokenCount, configModel);
    primary = usage.primary;
    secondary = usage.secondary;
    if (usage.todayTotalTokens > 0) {
      todayTotalTokens = usage.todayTotalTokens;
      todayTokensByModel = usage.todayTokensByModel;
      modelUsage = usage.modelUsage;
    }
  }

  function tryPreviousSession() {
    if (sessionIndex > 0)
      sessionIndex = sessionIndex - 1;
  }

  function refresh() {
    if (!enabled)
      return;
    historyFile.reload();
    configFile.reload();
    authFile.reload();
    sessionLister.running = true;
  }
}
