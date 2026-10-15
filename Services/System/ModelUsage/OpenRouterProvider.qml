import QtQuick
import Quickshell
import "../../../Helpers/ModelUsageLogic.js" as ModelUsageLogic
import qs.Commons

// OpenRouter: key info and the last 7 days of activity from the API
ModelUsageProvider {
  id: root

  providerId: "openrouter"
  providerName: "OpenRouter"
  helpText: I18n.tr("model-usage.help.openrouter")
  primary: ModelUsageLogic.emptyLimit("no-limit")

  property string configuredKey: ""
  readonly property string apiKey: ModelUsageLogic.resolveApiKey([Quickshell.env("OPENROUTER_API_KEY") || ""], configuredKey)

  Timer {
    interval: 5 * 60 * 1000
    running: root.enabled && root.apiKey !== ""
    repeat: true
    onTriggered: root.refresh()
  }

  onEnabledChanged: refresh()
  onApiKeyChanged: refresh()
  Component.onCompleted: refresh()

  function request(url, onDone) {
    const xhr = new XMLHttpRequest();
    xhr.open("GET", url);
    xhr.setRequestHeader("Authorization", "Bearer " + apiKey);
    xhr.onreadystatechange = function () {
      if (xhr.readyState === XMLHttpRequest.DONE)
        onDone(xhr);
    };
    xhr.send();
  }

  function fetchKeyInfo() {
    request("https://openrouter.ai/api/v1/key", xhr => {
      if (xhr.status !== 200) {
        Logger.w("ModelUsage", "OpenRouter key request failed, status", xhr.status);
        root.statusText = (xhr.status === 401 || xhr.status === 403) ? I18n.tr("model-usage.status.token-invalid") : "";
        return;
      }
      try {
        const data = JSON.parse(xhr.responseText);
        const key = ModelUsageLogic.parseOpenRouterKey(data.data || data);
        root.primary = key.primary;
        root.tierLabel = key.freeTier ? I18n.tr("model-usage.tier.free") : I18n.tr("model-usage.tier.paid");
        root.statusText = "";
        root.ready = true;
      } catch (e) {
        Logger.w("ModelUsage", "Failed to parse OpenRouter key info:", e);
      }
    });
  }

  function fetchActivity() {
    const days = ModelUsageLogic.lastDates(new Date(), 7);
    const entriesByDate = {};
    let pending = days.length;
    for (const date of days) {
      request("https://openrouter.ai/api/v1/activity?date=" + date, xhr => {
        let entries = [];
        if (xhr.status === 200) {
          try {
            entries = JSON.parse(xhr.responseText).data || [];
          } catch (e) {
            entries = [];
          }
        }
        entriesByDate[date] = entries;
        pending--;
        if (pending === 0) {
          const a = ModelUsageLogic.aggregateOpenRouterActivity(days, entriesByDate);
          root.recentDays = a.recentDays;
          root.modelUsage = a.modelUsage;
          root.todayPrompts = a.todayPrompts;
          root.todayTotalTokens = a.todayTotalTokens;
          root.todayTokensByModel = a.todayTokensByModel;
        }
      });
    }
  }

  function refresh() {
    if (!enabled)
      return;
    if (!apiKey) {
      statusText = I18n.tr("model-usage.status.api-key-required");
      ready = false;
      return;
    }
    fetchKeyInfo();
    fetchActivity();
  }
}
