pragma Singleton

import QtQuick
import Quickshell
import "../../Helpers/ModelUsageLogic.js" as ModelUsageLogic
import "../../Helpers/ModelUsageOrder.js" as ModelUsageOrder
import qs.Commons
import qs.Services.System.ModelUsage

// AI coding assistant usage (Claude Code, Codex, Copilot, Gemini, OpenRouter, Zen)
// for the ModelUsage bar widget and panel.
Singleton {
  id: root

  readonly property var cfg: Settings.data.modelUsage

  ClaudeProvider {
    id: claude
    enabled: root.cfg.claudeEnabled
  }
  CodexProvider {
    id: codex
    enabled: root.cfg.codexEnabled
  }
  CopilotProvider {
    id: copilot
    enabled: root.cfg.copilotEnabled
  }
  GeminiProvider {
    id: gemini
    enabled: root.cfg.geminiEnabled
  }
  OpenRouterProvider {
    id: openRouter
    enabled: root.cfg.openrouterEnabled
    configuredKey: root.cfg.openrouterApiKey
  }
  ZenProvider {
    id: zen
    enabled: root.cfg.zenEnabled
    configuredKey: root.cfg.zenApiKey
  }

  readonly property var providers: ModelUsageOrder.sortByOrder([claude, codex, copilot, gemini, openRouter, zen], root.cfg.providerOrder, p => p.providerId)
  readonly property var enabledProviders: providers.filter(p => p.enabled)

  // Fallback polling in case file watches miss a change
  Timer {
    interval: Math.max(5, root.cfg.refreshIntervalSec) * 1000
    running: root.enabledProviders.length > 0
    repeat: true
    onTriggered: root.refresh()
  }

  function refresh() {
    for (const p of enabledProviders)
      p.refresh();
  }

  // Translated label of a rate limit, see Helpers/ModelUsageLogic.js
  function limitLabel(limit) {
    if (!limit || !limit.kind)
      return "";
    return I18n.tr("model-usage.limits." + limit.kind, limit.params || {});
  }

  function init() {
    Logger.i("ModelUsage", "Service started");
  }
}
