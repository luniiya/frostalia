import QtQuick
import Quickshell
import Quickshell.Io
import "../../../Helpers/ModelUsageLogic.js" as ModelUsageLogic
import qs.Commons

// Claude Code: local stats/history files, plus rate limits from the OAuth usage endpoint
ModelUsageProvider {
  id: root

  providerId: "claude"
  providerName: "Claude Code"
  helpText: rateLimited ? I18n.tr("model-usage.help.rate-limited") : I18n.tr("model-usage.help.claude")
  primary: ModelUsageLogic.emptyLimit("weekly")
  secondary: ModelUsageLogic.emptyLimit("session")

  property string accessToken: ""
  property real expiresAtMs: 0
  // Earliest time the usage endpoint may be called again. The endpoint is rate
  // limited hard, so results are cached on disk and restarts reuse them.
  property real nextProbeAtMs: 0
  property bool rateLimited: false
  readonly property int probeMinIntervalMs: 5 * 60 * 1000

  FileView {
    id: statsFile
    path: root.enabled ? root.resolvePath("~/.claude/stats-cache.json") : ""
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      try {
        const s = ModelUsageLogic.parseClaudeStats(text(), ModelUsageLogic.localDateString(new Date()));
        root.todayTokensByModel = s.todayTokensByModel;
        root.todayTotalTokens = s.todayTotalTokens;
        root.recentDays = s.recentDays;
        root.modelUsage = s.modelUsage;
        root.totalPrompts = s.totalPrompts;
        root.totalSessions = s.totalSessions;
        root.ready = true;
      } catch (e) {
        Logger.w("ModelUsage", "Failed to parse Claude stats-cache.json:", e);
      }
    }
  }

  FileView {
    id: historyFile
    path: root.enabled ? root.resolvePath("~/.claude/history.jsonl") : ""
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      const h = ModelUsageLogic.countTodayHistory(text(), ModelUsageLogic.startOfDayMs(new Date()), "timestamp", 1, "sessionId");
      root.todayPrompts = h.prompts;
      root.todaySessions = h.sessions;
      root.ready = true;
    }
  }

  FileView {
    id: credentialsFile
    path: root.enabled ? root.resolvePath("~/.claude/.credentials.json") : ""
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.applyCredentials(text())
    onLoadFailed: root.applyCredentials("")
  }

  FileView {
    id: cacheFile
    path: Settings.cacheDir + "model-usage-claude.json"
    blockAllReads: true
    printErrors: false
  }

  Timer {
    interval: root.probeMinIntervalMs
    running: root.enabled && root.accessToken !== ""
    repeat: true
    onTriggered: root.probeRateLimits()
  }

  Component.onCompleted: loadCache()

  function loadCache() {
    const cached = ModelUsageLogic.parseLimitsCache(cacheFile.text());
    if (!cached)
      return;
    primary = cached.primary;
    secondary = cached.secondary;
    nextProbeAtMs = Math.max(nextProbeAtMs, cached.fetchedAtMs + probeMinIntervalMs);
  }

  function applyCredentials(content) {
    let creds = null;
    try {
      creds = content ? ModelUsageLogic.parseClaudeCredentials(content) : null;
    } catch (e) {
      Logger.w("ModelUsage", "Failed to parse Claude credentials:", e);
    }
    // Claude Code rotates tokens regularly; that alone is no reason to call the endpoint again
    accessToken = creds ? creds.accessToken : "";
    expiresAtMs = creds ? creds.expiresAtMs : 0;
    tierLabel = creds ? ModelUsageLogic.claudeTierLabel(creds.subscriptionType, creds.rateLimitTier) : "";
    probeRateLimits();
  }

  function probeRateLimits() {
    if (!accessToken) {
      statusText = I18n.tr("model-usage.status.waiting-auth");
      clearLimits();
      return;
    }
    if (ModelUsageLogic.claudeTokenExpired(accessToken, expiresAtMs, Date.now())) {
      statusText = I18n.tr("model-usage.status.token-expired");
      clearLimits();
      return;
    }
    if (!rateLimited)
      statusText = "";
    const now = Date.now();
    if (now < nextProbeAtMs)
      return;
    nextProbeAtMs = now + probeMinIntervalMs;

    const xhr = new XMLHttpRequest();
    xhr.open("GET", "https://api.anthropic.com/api/oauth/usage");
    xhr.setRequestHeader("Authorization", "Bearer " + accessToken);
    xhr.setRequestHeader("anthropic-beta", "oauth-2025-04-20");
    xhr.setRequestHeader("Accept", "application/json");
    xhr.onreadystatechange = function () {
      if (xhr.readyState !== XMLHttpRequest.DONE)
        return;
      root.handleUsageResponse(xhr.status, xhr.responseText, xhr.getResponseHeader("retry-after"));
    };
    xhr.send();
  }

  function handleUsageResponse(status, body, retryAfter) {
    const now = Date.now();
    if (status === 401 || status === 403) {
      rateLimited = false;
      statusText = I18n.tr("model-usage.status.token-expired");
      clearLimits();
      return;
    }
    if (status === 429) {
      // Keep the last known limits and wait as long as the API asks
      nextProbeAtMs = now + ModelUsageLogic.retryDelayMs(retryAfter, now, probeMinIntervalMs);
      rateLimited = true;
      statusText = primary.percent >= 0 ? "" : I18n.tr("model-usage.status.rate-limited", {
                                                         "time": ModelUsageLogic.formatResetTime(new Date(nextProbeAtMs).toISOString(), now)
                                                       });
      Logger.d("ModelUsage", "Claude usage rate limited, next try in", Math.round((nextProbeAtMs - now) / 1000), "s");
      return;
    }
    if (status >= 200 && status < 300) {
      try {
        const limits = ModelUsageLogic.parseClaudeOAuthUsage(JSON.parse(body || "{}"));
        if (limits) {
          rateLimited = false;
          statusText = "";
          primary = limits.primary;
          secondary = limits.secondary;
          cacheFile.setText(ModelUsageLogic.serializeLimitsCache(primary, secondary, now));
          return;
        }
      } catch (e) {
        Logger.w("ModelUsage", "Failed to parse Claude usage response:", e);
      }
    } else {
      Logger.w("ModelUsage", "Claude usage request failed, status", status);
    }
  }

  function refresh() {
    if (!enabled)
      return;
    statsFile.reload();
    historyFile.reload();
    credentialsFile.reload();
  }
}
