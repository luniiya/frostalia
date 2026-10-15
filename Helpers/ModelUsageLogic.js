.pragma library

// Pure logic for the AI model usage service, bar widget and panel. Kept free of
// QML/Quickshell dependencies so it can be unit tested (see Tests/tst_modelusage.qml).
//
// A rate limit is { percent, resetAt, kind, params }:
//   percent  used share in [0, 1], or -1 when unknown
//   resetAt  ISO timestamp, or ""
//   kind     label key under "model-usage.limits" (translated by the caller)
//   params   values for the translated label

var providerIds = ["claude", "codex", "copilot", "gemini", "openrouter", "zen"];

function emptyLimit(kind) {
  return {
    "percent": -1,
    "resetAt": "",
    "kind": kind || "",
    "params": {}
  };
}

function formatTokenCount(n) {
  if (n === undefined || n === null || !isFinite(n))
    return "0";
  if (n >= 1e9)
    return (n / 1e9).toFixed(1) + "B";
  if (n >= 1e6)
    return (n / 1e6).toFixed(1) + "M";
  if (n >= 1e3)
    return (n / 1e3).toFixed(1) + "K";
  return String(n);
}

// "claude-opus-4-5-20251101" -> "Opus 4.5"
function friendlyModelName(id) {
  if (!id)
    return "Unknown";
  var name = String(id).replace(/^claude-/, "").replace(/-\d{8}$/, "");
  var parts = name.split("-");
  var family = parts[0].charAt(0).toUpperCase() + parts[0].slice(1);
  if (parts.length >= 3)
    return family + " " + parts[1] + "." + parts[2];
  if (parts.length === 2)
    return family + " " + parts[1];
  return family;
}

// Time until an ISO timestamp: "" (none), "now", "2d 3h", "3h 5m" or "5m"
function formatResetTime(isoTimestamp, nowMs) {
  if (!isoTimestamp)
    return "";
  var reset = new Date(isoTimestamp).getTime();
  if (isNaN(reset))
    return "";
  var diffMs = reset - nowMs;
  if (diffMs <= 0)
    return "now";
  var hours = Math.floor(diffMs / 3600000);
  var mins = Math.floor((diffMs % 3600000) / 60000);
  if (hours > 24)
    return Math.floor(hours / 24) + "d " + (hours % 24) + "h";
  if (hours > 0)
    return hours + "h " + mins + "m";
  return mins + "m";
}

// Accepts 0-1 fractions, 0-100 percentages and "42%" strings; -1 when unknown
function normalizeUtilization(value) {
  if (value === null || value === undefined)
    return -1;
  var n = parseFloat(String(value).trim().replace("%", ""));
  if (!(n >= 0))
    return -1;
  return Math.min(1, n > 1 ? n / 100 : n);
}

// Epoch seconds/milliseconds (number or digit string) or a date string -> ISO, "" when invalid
function normalizeResetAt(value) {
  if (value === null || value === undefined)
    return "";
  var raw = String(value).trim();
  if (raw === "")
    return "";
  var d;
  if (/^\d+(\.\d+)?$/.test(raw)) {
    var ts = parseFloat(raw);
    d = new Date(ts < 1e12 ? ts * 1000 : ts);
  } else {
    d = new Date(raw);
  }
  return isNaN(d.getTime()) ? "" : d.toISOString();
}

function localDateString(date) {
  return date.getFullYear() + "-" + String(date.getMonth() + 1).padStart(2, "0") + "-" + String(date.getDate()).padStart(2, "0");
}

function startOfDayMs(date) {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate()).getTime();
}

// The last `count` local dates, oldest first, ending with `date`
function lastDates(date, count) {
  var days = [];
  for (var i = count - 1; i >= 0; i--) {
    var d = new Date(date.getFullYear(), date.getMonth(), date.getDate() - i);
    days.push(localDateString(d));
  }
  return days;
}

function usageLevel(percent) {
  if (percent >= 0.9)
    return "critical";
  if (percent >= 0.7)
    return "warning";
  return "normal";
}

function sumValues(obj) {
  var total = 0;
  for (var k in obj)
    total += Number(obj[k]) || 0;
  return total;
}

// Counts today's prompts and distinct sessions in a JSONL history, newest entries last.
// `timeField` holds epoch time in `timeScale` units per millisecond (1 for ms, 0.001 for seconds).
function countTodayHistory(content, dayStartMs, timeField, timeScale, sessionField) {
  var lines = String(content || "").split("\n");
  var prompts = 0;
  var sessions = {};
  var threshold = dayStartMs * timeScale;
  for (var i = lines.length - 1; i >= 0; i--) {
    var line = lines[i].trim();
    if (!line)
      continue;
    var entry;
    try {
      entry = JSON.parse(line);
    } catch (e) {
      continue;
    }
    if ((entry[timeField] || 0) < threshold)
      break;
    prompts++;
    if (entry[sessionField])
      sessions[entry[sessionField]] = true;
  }
  return {
    "prompts": prompts,
    "sessions": Object.keys(sessions).length
  };
}

// ~/.claude/stats-cache.json
function parseClaudeStats(content, today) {
  var data = JSON.parse(content);
  var todayEntry = (data.dailyModelTokens || []).find(function (d) {
    return d.date === today;
  });
  var byModel = (todayEntry && todayEntry.tokensByModel) || {};
  var daily = data.dailyActivity || [];
  return {
    "todayTokensByModel": byModel,
    "todayTotalTokens": sumValues(byModel),
    "recentDays": daily.slice(-7),
    "modelUsage": data.modelUsage || {},
    "totalPrompts": data.totalMessages || 0,
    "totalSessions": data.totalSessions || 0
  };
}

// ~/.claude/.credentials.json
function parseClaudeCredentials(content) {
  var oauth = JSON.parse(content).claudeAiOauth || {};
  var expires = Number(oauth.expiresAt || 0);
  return {
    "accessToken": oauth.accessToken || "",
    "expiresAtMs": (isFinite(expires) && expires > 0) ? expires : 0,
    "subscriptionType": oauth.subscriptionType || "",
    "rateLimitTier": oauth.rateLimitTier || ""
  };
}

function claudeTokenExpired(accessToken, expiresAtMs, nowMs) {
  if (!accessToken)
    return true;
  return expiresAtMs > 0 && expiresAtMs <= nowMs;
}

function claudeTierLabel(subscriptionType, rateLimitTier) {
  var match = String(rateLimitTier || "").match(/max_(\d+x)/i);
  if (match)
    return "Max " + match[1];
  if (subscriptionType)
    return subscriptionType.charAt(0).toUpperCase() + subscriptionType.slice(1);
  return "";
}

// Response of https://api.anthropic.com/api/oauth/usage -> { primary, secondary }, or null
function parseClaudeOAuthUsage(payload) {
  function bucket(key) {
    var b = payload ? payload[key] : null;
    return (b && typeof b === "object") ? b : null;
  }
  var weekly = bucket("seven_day_oauth_apps") || bucket("seven_day");
  var session = bucket("five_hour");
  var weeklyPct = normalizeUtilization(weekly ? weekly.utilization : null);
  var sessionPct = normalizeUtilization(session ? session.utilization : null);
  if (weeklyPct < 0 && sessionPct < 0)
    return null;

  var primary = emptyLimit("weekly");
  var secondary = emptyLimit("session");
  if (weeklyPct >= 0) {
    primary.percent = weeklyPct;
    primary.resetAt = normalizeResetAt(weekly.resets_at);
  }
  if (sessionPct >= 0) {
    secondary.percent = sessionPct;
    secondary.resetAt = normalizeResetAt(session.resets_at);
  }
  // Only a session bucket: show it as the main limit
  if (primary.percent < 0)
    return {
      "primary": secondary,
      "secondary": emptyLimit("session")
    };
  return {
    "primary": primary,
    "secondary": secondary
  };
}

// Serialized Claude rate limits, saved so a restart does not need a new request
function serializeLimitsCache(primary, secondary, fetchedAtMs) {
  return JSON.stringify({
                          "fetchedAtMs": fetchedAtMs,
                          "primary": primary,
                          "secondary": secondary
                        });
}

// Cached limits { primary, secondary, fetchedAtMs }, or null when missing or malformed
function parseLimitsCache(text) {
  if (!text)
    return null;
  try {
    var c = JSON.parse(text);
    if (!c || !(c.fetchedAtMs > 0) || !c.primary || !c.secondary)
      return null;
    return {
      "primary": c.primary,
      "secondary": c.secondary,
      "fetchedAtMs": c.fetchedAtMs
    };
  } catch (e) {
    return null;
  }
}

// Milliseconds to wait after a 429: the Retry-After header (seconds or HTTP date), at least `minMs`
function retryDelayMs(retryAfter, nowMs, minMs) {
  var raw = String(retryAfter || "").trim();
  var ms = 0;
  if (/^\d+$/.test(raw)) {
    ms = parseInt(raw, 10) * 1000;
  } else if (raw !== "") {
    var at = new Date(raw).getTime();
    if (!isNaN(at))
      ms = at - nowMs;
  }
  return Math.max(minMs, ms);
}

function codexConfigModel(content) {
  var match = String(content || "").match(/model\s*=\s*"([^"]+)"/);
  return match ? match[1] : "";
}

// The newest token_count event in a Codex session JSONL, or null
function codexLastTokenCount(content) {
  var lines = String(content || "").split("\n");
  for (var i = lines.length - 1; i >= 0; i--) {
    var line = lines[i].trim();
    if (!line)
      continue;
    var entry;
    try {
      entry = JSON.parse(line);
    } catch (e) {
      continue;
    }
    var p = entry.payload;
    if (entry.type === "event_msg" && p && p.type === "token_count")
      return p;
    if (entry.type === "token_count")
      return entry;
    if (entry.type === "response_item" && p && p.type === "event_msg" && p.payload && p.payload.type === "token_count")
      return p.payload;
  }
  return null;
}

function codexLimit(rl, fallbackKind) {
  if (!rl)
    return emptyLimit(fallbackKind);
  var limit = emptyLimit(fallbackKind);
  limit.percent = Math.max(0, Math.min(1, (rl.used_percent || 0) / 100));
  if (rl.window_minutes === 10080) {
    limit.kind = "weekly";
  } else if (rl.window_minutes) {
    limit.kind = "window";
    limit.params = {
      "hours": Math.round(rl.window_minutes / 60)
    };
  }
  if (rl.resets_at)
    limit.resetAt = normalizeResetAt(rl.resets_at);
  return limit;
}

// token_count event -> limits and token usage
function codexUsage(tokenCount, configModel) {
  var limits = tokenCount.rate_limits || {};
  var result = {
    "primary": limits.primary ? codexLimit(limits.primary, "weekly") : emptyLimit("weekly"),
    "secondary": limits.secondary ? codexLimit(limits.secondary, "secondary") : emptyLimit(""),
    "todayTotalTokens": 0,
    "todayTokensByModel": {},
    "modelUsage": {}
  };
  var usage = tokenCount.info ? tokenCount.info.total_token_usage : null;
  if (usage) {
    var input = usage.input_tokens || 0;
    var output = usage.output_tokens || 0;
    var cached = usage.cached_input_tokens || 0;
    var reasoning = usage.reasoning_output_tokens || 0;
    var model = configModel || "codex";
    result.todayTotalTokens = input + output + cached + reasoning;
    result.todayTokensByModel[model] = result.todayTotalTokens;
    result.modelUsage[model] = {
      "inputTokens": input,
      "outputTokens": output + reasoning,
      "cacheReadInputTokens": cached,
      "cacheCreationInputTokens": 0
    };
  }
  return result;
}

// Concatenated Gemini CLI session JSONL files for today
function parseGeminiSessions(content) {
  var lines = String(content || "").split("\n");
  var prompts = 0;
  var tokens = 0;
  var byModel = {};
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i].trim();
    if (!line)
      continue;
    var entry;
    try {
      entry = JSON.parse(line);
    } catch (e) {
      continue;
    }
    if (entry.type === "user") {
      prompts++;
    } else if (entry.type === "gemini" && entry.tokens) {
      var t = entry.tokens.total || 0;
      var model = entry.model || "gemini";
      tokens += t;
      byModel[model] = (byModel[model] || 0) + t;
    }
  }
  return {
    "prompts": prompts,
    "tokens": tokens,
    "tokensByModel": byModel
  };
}

function capitalize(s) {
  s = String(s || "");
  return s ? s.charAt(0).toUpperCase() + s.slice(1) : "";
}

// Free-tier Copilot quota for one key, or null when not reported
function copilotQuota(left, monthly, key, kind, resetAt) {
  if (typeof left[key] !== "number" || typeof monthly[key] !== "number" || !(monthly[key] > 0))
    return null;
  var used = monthly[key] - left[key];
  return {
    "percent": Math.min(100, Math.max(0, Math.round(used / monthly[key] * 100))) / 100,
    "resetAt": resetAt,
    "kind": kind,
    "params": {
      "used": used,
      "total": monthly[key]
    }
  };
}

// Response of https://api.github.com/copilot_internal/user
function parseCopilotUsage(data) {
  var result = {
    "tier": capitalize(data.copilot_plan),
    "primary": emptyLimit("premium"),
    "secondary": emptyLimit("chat")
  };

  var snapshots = data.quota_snapshots;
  var reset = normalizeResetAt(data.quota_reset_date);
  if (snapshots) {
    var premium = snapshots.premium_interactions;
    if (premium && typeof premium.percent_remaining === "number") {
      var usedPremium = Math.min(100, Math.max(0, 100 - premium.percent_remaining));
      result.primary = {
        "percent": usedPremium / 100,
        "resetAt": reset,
        "kind": "premium",
        "params": {
          "percent": Math.round(usedPremium)
        }
      };
    }
    var chat = snapshots.chat;
    if (chat && typeof chat.percent_remaining === "number") {
      var usedChat = Math.min(100, Math.max(0, 100 - chat.percent_remaining));
      result.secondary = {
        "percent": usedChat / 100,
        "resetAt": reset,
        "kind": "chat",
        "params": {
          "percent": Math.round(usedChat)
        }
      };
    }
  }

  // Free tier
  var lq = data.limited_user_quotas;
  var mq = data.monthly_quotas;
  if (lq && mq) {
    var freeReset = normalizeResetAt(data.limited_user_reset_date);
    var chatQuota = copilotQuota(lq, mq, "chat", "chat-count", freeReset);
    var completionsQuota = copilotQuota(lq, mq, "completions", "completions-count", freeReset);
    if (chatQuota)
      result.primary = chatQuota;
    if (completionsQuota)
      result.secondary = completionsQuota;
  }
  return result;
}

function finiteOr(value, fallback) {
  if (value === null || value === undefined)
    return fallback;
  var n = Number(value);
  return isFinite(n) ? n : fallback;
}

// data field of https://openrouter.ai/api/v1/key
function parseOpenRouterKey(info) {
  var weekly = finiteOr(info.usage_weekly, 0);
  var limit = finiteOr(info.limit, -1);
  var remaining = finiteOr(info.limit_remaining, -1);
  var primary = emptyLimit("no-limit");
  primary.resetAt = normalizeResetAt(info.limit_reset);
  if (limit > 0) {
    primary.percent = Math.min(1, Math.max(0, weekly / limit));
    primary.kind = "spending";
    primary.params = {
      "used": weekly.toFixed(2),
      "limit": limit.toFixed(2)
    };
  } else if (remaining >= 0 && weekly + remaining > 0) {
    var budget = weekly + remaining;
    primary.percent = Math.min(1, Math.max(0, weekly / budget));
    primary.kind = "budget";
    primary.params = {
      "used": weekly.toFixed(2),
      "limit": budget.toFixed(2)
    };
  } else {
    primary.percent = 0;
  }
  return {
    "primary": primary,
    "freeTier": !!info.is_free_tier
  };
}

// Per-day OpenRouter activity ({ date: [entries] }) -> stats for the last days
function aggregateOpenRouterActivity(days, entriesByDate) {
  var recentDays = [];
  var models = {};
  for (var i = 0; i < days.length; i++) {
    var entries = entriesByDate[days[i]] || [];
    var requests = 0;
    for (var j = 0; j < entries.length; j++) {
      var e = entries[j];
      var model = e.model || "unknown";
      requests += e.requests || 0;
      if (!models[model])
        models[model] = {
          "inputTokens": 0,
          "outputTokens": 0,
          "cacheReadInputTokens": 0,
          "cacheCreationInputTokens": 0
        };
      models[model].inputTokens += e.prompt_tokens || 0;
      models[model].outputTokens += e.completion_tokens || 0;
    }
    recentDays.push({
                      "date": days[i],
                      "messageCount": requests
                    });
  }

  var today = entriesByDate[days[days.length - 1]] || [];
  var todayByModel = {};
  var todayTokens = 0;
  for (var k = 0; k < today.length; k++) {
    var t = (today[k].prompt_tokens || 0) + (today[k].completion_tokens || 0);
    var m = today[k].model || "unknown";
    todayByModel[m] = (todayByModel[m] || 0) + t;
    todayTokens += t;
  }
  return {
    "recentDays": recentDays,
    "modelUsage": models,
    "todayPrompts": recentDays.length > 0 ? recentDays[recentDays.length - 1].messageCount : 0,
    "todayTotalTokens": todayTokens,
    "todayTokensByModel": todayByModel
  };
}

// First non-empty value: environment variables in order, then the configured key
function resolveApiKey(envValues, configured) {
  for (var i = 0; i < envValues.length; i++) {
    if (envValues[i])
      return envValues[i];
  }
  return configured || "";
}

// Text shown in the bar for a provider snapshot and metric ("prompts", "tokens" or "usage")
function barText(provider, metric) {
  if (!provider)
    return "—";
  if (metric === "usage") {
    var p = provider.primary ? provider.primary.percent : -1;
    var s = provider.secondary ? provider.secondary.percent : -1;
    if (!(p >= 0))
      return provider.statusText ? provider.statusText : "—";
    var text = Math.round(p * 100) + "%";
    if (s >= 0)
      text += "·" + Math.round(s * 100) + "%";
    return text;
  }
  if (metric === "tokens")
    return formatTokenCount(provider.todayTotalTokens);
  return String(provider.todayPrompts || 0);
}

// Index of the provider to show, kept in range as providers are toggled
function clampIndex(index, count) {
  if (count <= 0 || index < 0 || index >= count)
    return 0;
  return index;
}

// Sorted object entries as [{ key, value }] for repeaters
function entries(obj) {
  var result = [];
  for (var k in (obj || {}))
    result.push({
                  "key": k,
                  "value": obj[k]
                });
  result.sort(function (a, b) {
    return a.key < b.key ? -1 : (a.key > b.key ? 1 : 0);
  });
  return result;
}

// --- Migration from the "model-usage" plugin -------------------------------

var pluginWidgetId = "plugin:model-usage";
var widgetId = "ModelUsage";

// Plugin settings.json -> values for Settings.data.modelUsage
function settingsFromPlugin(plugin) {
  plugin = plugin || {};
  var providers = plugin.providers || {};
  var enabled = {};
  for (var i = 0; i < providerIds.length; i++) {
    var p = providers[providerIds[i]];
    enabled[providerIds[i]] = !!(p && p.enabled);
  }
  var refresh = Number(plugin.refreshIntervalSec);
  return {
    "enabled": enabled,
    "refreshIntervalSec": (isFinite(refresh) && refresh >= 5) ? Math.min(300, Math.round(refresh)) : 30,
    "openrouterApiKey": (providers.openrouter && providers.openrouter.apiKey) || "",
    "zenApiKey": (providers.zen && providers.zen.apiKey) || ""
  };
}

// Plugin settings.json -> per-widget settings of the native bar widget
function widgetFromPlugin(plugin) {
  plugin = plugin || {};
  var cycle = Number(plugin.barCycleIntervalSec);
  return {
    "id": widgetId,
    "displayMode": plugin.barDisplayMode === "cycle" ? "cycle" : "active",
    "cycleIntervalSec": (isFinite(cycle) && cycle >= 2) ? Math.min(60, Math.round(cycle)) : 5,
    "metric": ["prompts", "tokens", "usage"].indexOf(plugin.barMetric) >= 0 ? plugin.barMetric : "prompts"
  };
}

// Replaces the plugin bar widget in { left, center, right } sections. When the bar
// already has the native widget, the plugin widget is dropped instead so it is not
// shown twice. Returns a new object, or null when there was nothing to change.
function migrateBarWidgets(sections, plugin) {
  if (!sections)
    return null;
  var hasNative = false;
  for (var s in sections) {
    if (Array.isArray(sections[s]) && sections[s].some(function (w) {
      return w && w.id === widgetId;
    }))
      hasNative = true;
  }
  var changed = false;
  var result = {};
  for (var key in sections) {
    var list = sections[key];
    if (!Array.isArray(list)) {
      result[key] = list;
      continue;
    }
    var migrated = [];
    for (var i = 0; i < list.length; i++) {
      var w = list[i];
      if (w && w.id === pluginWidgetId) {
        changed = true;
        if (!hasNative) {
          migrated.push(widgetFromPlugin(plugin));
          hasNative = true;
        }
      } else {
        migrated.push(w);
      }
    }
    result[key] = migrated;
  }
  return changed ? result : null;
}
