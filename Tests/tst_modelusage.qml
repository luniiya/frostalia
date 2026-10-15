import QtQuick
import QtTest
import "../Helpers/ModelUsageLogic.js" as ModelUsage

TestCase {
  name: "ModelUsage"

  function test_formatTokenCount_data() {
    return [
          {
            tag: "small",
            n: 42,
            e: "42"
          },
          {
            tag: "thousands",
            n: 1500,
            e: "1.5K"
          },
          {
            tag: "millions",
            n: 2340000,
            e: "2.3M"
          },
          {
            tag: "billions",
            n: 7e9,
            e: "7.0B"
          },
          {
            tag: "null",
            n: null,
            e: "0"
          },
          {
            tag: "undefined",
            n: undefined,
            e: "0"
          }
        ];
  }
  function test_formatTokenCount(d) {
    compare(ModelUsage.formatTokenCount(d.n), d.e);
  }

  function test_friendlyModelName_data() {
    return [
          {
            tag: "dated claude",
            id: "claude-opus-4-5-20251101",
            e: "Opus 4.5"
          },
          {
            tag: "two parts",
            id: "gpt-5",
            e: "Gpt 5"
          },
          {
            tag: "single",
            id: "codex",
            e: "Codex"
          },
          {
            tag: "empty",
            id: "",
            e: "Unknown"
          }
        ];
  }
  function test_friendlyModelName(d) {
    compare(ModelUsage.friendlyModelName(d.id), d.e);
  }

  function test_formatResetTime() {
    var now = Date.UTC(2026, 0, 1, 12, 0, 0);
    compare(ModelUsage.formatResetTime("", now), "");
    compare(ModelUsage.formatResetTime("garbage", now), "");
    compare(ModelUsage.formatResetTime(new Date(now - 1000).toISOString(), now), "now");
    compare(ModelUsage.formatResetTime(new Date(now + 5 * 60000).toISOString(), now), "5m");
    compare(ModelUsage.formatResetTime(new Date(now + 3 * 3600000 + 7 * 60000).toISOString(), now), "3h 7m");
    compare(ModelUsage.formatResetTime(new Date(now + 50 * 3600000).toISOString(), now), "2d 2h");
  }

  function test_normalizeUtilization_data() {
    return [
          {
            tag: "fraction",
            v: 0.25,
            e: 0.25
          },
          {
            tag: "percent",
            v: 42,
            e: 0.42
          },
          {
            tag: "percent string",
            v: "80%",
            e: 0.8
          },
          {
            tag: "over 100 clamps",
            v: 150,
            e: 1
          },
          {
            tag: "null",
            v: null,
            e: -1
          },
          {
            tag: "negative",
            v: -3,
            e: -1
          },
          {
            tag: "junk",
            v: "abc",
            e: -1
          }
        ];
  }
  function test_normalizeUtilization(d) {
    fuzzyCompare(ModelUsage.normalizeUtilization(d.v), d.e, 1e-9);
  }

  function test_normalizeResetAt() {
    var iso = "2026-01-01T00:00:00.000Z";
    var secs = Date.parse(iso) / 1000;
    compare(ModelUsage.normalizeResetAt(secs), iso);
    compare(ModelUsage.normalizeResetAt(String(secs)), iso);
    compare(ModelUsage.normalizeResetAt(secs * 1000), iso);
    compare(ModelUsage.normalizeResetAt(iso), iso);
    compare(ModelUsage.normalizeResetAt(""), "");
    compare(ModelUsage.normalizeResetAt(null), "");
    compare(ModelUsage.normalizeResetAt("not a date"), "");
  }

  function test_lastDates() {
    compare(ModelUsage.lastDates(new Date(2026, 2, 2), 3), ["2026-02-28", "2026-03-01", "2026-03-02"]);
  }

  function test_usageLevel() {
    compare(ModelUsage.usageLevel(0.5), "normal");
    compare(ModelUsage.usageLevel(0.7), "warning");
    compare(ModelUsage.usageLevel(0.95), "critical");
  }

  function test_countTodayHistory_claude() {
    var day = new Date(2026, 0, 2).getTime();
    var content = [JSON.stringify({
                                    timestamp: day - 1000,
                                    sessionId: "old"
                                  }), JSON.stringify({
                                                       timestamp: day + 1000,
                                                       sessionId: "a"
                                                     }), "not json", JSON.stringify({
                                                                                      timestamp: day + 2000,
                                                                                      sessionId: "a"
                                                                                    }), JSON.stringify({
                                                                                                         timestamp: day + 3000,
                                                                                                         sessionId: "b"
                                                                                                       }), ""].join("\n");
    var r = ModelUsage.countTodayHistory(content, day, "timestamp", 1, "sessionId");
    compare(r.prompts, 3);
    compare(r.sessions, 2);
  }

  function test_countTodayHistory_codexSeconds() {
    var day = new Date(2026, 0, 2).getTime();
    var content = [JSON.stringify({
                                    ts: day / 1000 - 5,
                                    session_id: "old"
                                  }), JSON.stringify({
                                                       ts: day / 1000 + 5,
                                                       session_id: "x"
                                                     })].join("\n");
    var r = ModelUsage.countTodayHistory(content, day, "ts", 0.001, "session_id");
    compare(r.prompts, 1);
    compare(r.sessions, 1);
  }

  function test_parseClaudeStats() {
    var days = [];
    for (var i = 1; i <= 9; i++)
      days.push({
                  date: "2026-01-0" + i,
                  messageCount: i
                });
    var r = ModelUsage.parseClaudeStats(JSON.stringify({
                                                         dailyModelTokens: [
                                                           {
                                                             date: "2026-01-09",
                                                             tokensByModel: {
                                                               a: 10,
                                                               b: 5
                                                             }
                                                           }
                                                         ],
                                                         dailyActivity: days,
                                                         modelUsage: {
                                                           a: {
                                                             inputTokens: 1
                                                           }
                                                         },
                                                         totalMessages: 99,
                                                         totalSessions: 7
                                                       }), "2026-01-09");
    compare(r.todayTotalTokens, 15);
    compare(r.recentDays.length, 7);
    compare(r.recentDays[0].messageCount, 3);
    compare(r.totalPrompts, 99);
    compare(r.totalSessions, 7);
  }

  function test_parseClaudeStats_noToday() {
    var r = ModelUsage.parseClaudeStats("{}", "2026-01-09");
    compare(r.todayTotalTokens, 0);
    compare(r.recentDays.length, 0);
  }

  function test_claudeCredentialsAndTier() {
    var c = ModelUsage.parseClaudeCredentials(JSON.stringify({
                                                               claudeAiOauth: {
                                                                 accessToken: "t",
                                                                 expiresAt: 5000,
                                                                 subscriptionType: "pro",
                                                                 rateLimitTier: "default_claude_max_20x"
                                                               }
                                                             }));
    compare(c.accessToken, "t");
    compare(c.expiresAtMs, 5000);
    compare(ModelUsage.claudeTierLabel(c.subscriptionType, c.rateLimitTier), "Max 20x");
    compare(ModelUsage.claudeTierLabel("pro", ""), "Pro");
    compare(ModelUsage.claudeTierLabel("", ""), "");
    verify(ModelUsage.claudeTokenExpired("t", 5000, 6000));
    verify(!ModelUsage.claudeTokenExpired("t", 5000, 4000));
    verify(!ModelUsage.claudeTokenExpired("t", 0, 4000));
    verify(ModelUsage.claudeTokenExpired("", 0, 4000));
  }

  function test_parseClaudeOAuthUsage() {
    var r = ModelUsage.parseClaudeOAuthUsage({
                                               seven_day: {
                                                 utilization: 40,
                                                 resets_at: "2026-01-08T00:00:00Z"
                                               },
                                               five_hour: {
                                                 utilization: 0.1,
                                                 resets_at: null
                                               }
                                             });
    fuzzyCompare(r.primary.percent, 0.4, 1e-9);
    compare(r.primary.kind, "weekly");
    compare(r.primary.resetAt, "2026-01-08T00:00:00.000Z");
    fuzzyCompare(r.secondary.percent, 0.1, 1e-9);
    compare(r.secondary.kind, "session");
    compare(ModelUsage.parseClaudeOAuthUsage({}), null);
  }

  function test_parseClaudeOAuthUsage_sessionOnly() {
    var r = ModelUsage.parseClaudeOAuthUsage({
                                               five_hour: {
                                                 utilization: 55
                                               }
                                             });
    fuzzyCompare(r.primary.percent, 0.55, 1e-9);
    compare(r.primary.kind, "session");
    compare(r.secondary.percent, -1);
  }

  function test_limitsCacheRoundTrip() {
    var primary = {
      percent: 0.4,
      resetAt: "2026-01-08T00:00:00.000Z",
      kind: "weekly",
      params: {}
    };
    var secondary = {
      percent: 0.1,
      resetAt: "",
      kind: "session",
      params: {}
    };
    var c = ModelUsage.parseLimitsCache(ModelUsage.serializeLimitsCache(primary, secondary, 1234));
    compare(c.fetchedAtMs, 1234);
    compare(c.primary, primary);
    compare(c.secondary, secondary);
  }

  function test_parseLimitsCache_invalid() {
    compare(ModelUsage.parseLimitsCache(""), null);
    compare(ModelUsage.parseLimitsCache("{broken"), null);
    compare(ModelUsage.parseLimitsCache(JSON.stringify({
                                                         primary: {},
                                                         secondary: {}
                                                       })), null);
  }

  function test_retryDelayMs() {
    var now = Date.UTC(2026, 0, 1, 12, 0, 0);
    compare(ModelUsage.retryDelayMs("120", now, 60000), 120000);
    compare(ModelUsage.retryDelayMs("5", now, 60000), 60000);
    compare(ModelUsage.retryDelayMs("", now, 60000), 60000);
    compare(ModelUsage.retryDelayMs(null, now, 60000), 60000);
    compare(ModelUsage.retryDelayMs(new Date(now + 600000).toUTCString(), now, 60000), 600000);
  }

  function test_codexConfigModel() {
    compare(ModelUsage.codexConfigModel('approval = "x"\nmodel = "gpt-5-codex"\n'), "gpt-5-codex");
    compare(ModelUsage.codexConfigModel(""), "");
  }

  function test_codexLastTokenCount() {
    var content = [JSON.stringify({
                                    type: "event_msg",
                                    payload: {
                                      type: "token_count",
                                      id: 1
                                    }
                                  }), JSON.stringify({
                                                       type: "event_msg",
                                                       payload: {
                                                         type: "token_count",
                                                         id: 2
                                                       }
                                                     }), JSON.stringify({
                                                                          type: "message"
                                                                        })].join("\n");
    compare(ModelUsage.codexLastTokenCount(content).id, 2);
    compare(ModelUsage.codexLastTokenCount(JSON.stringify({
                                                            type: "token_count",
                                                            id: 3
                                                          })).id, 3);
    compare(ModelUsage.codexLastTokenCount(JSON.stringify({
                                                            type: "response_item",
                                                            payload: {
                                                              type: "event_msg",
                                                              payload: {
                                                                type: "token_count",
                                                                id: 4
                                                              }
                                                            }
                                                          })).id, 4);
    compare(ModelUsage.codexLastTokenCount("nothing"), null);
  }

  function test_codexUsage() {
    var r = ModelUsage.codexUsage({
                                    rate_limits: {
                                      primary: {
                                        used_percent: 30,
                                        window_minutes: 300,
                                        resets_at: 1767225600
                                      },
                                      secondary: {
                                        used_percent: 10,
                                        window_minutes: 10080
                                      }
                                    },
                                    info: {
                                      total_token_usage: {
                                        input_tokens: 100,
                                        output_tokens: 20,
                                        cached_input_tokens: 50,
                                        reasoning_output_tokens: 5
                                      }
                                    }
                                  }, "gpt-5");
    fuzzyCompare(r.primary.percent, 0.3, 1e-9);
    compare(r.primary.kind, "window");
    compare(r.primary.params.hours, 5);
    compare(r.primary.resetAt, "2026-01-01T00:00:00.000Z");
    compare(r.secondary.kind, "weekly");
    compare(r.todayTotalTokens, 175);
    compare(r.todayTokensByModel["gpt-5"], 175);
    compare(r.modelUsage["gpt-5"].outputTokens, 25);
  }

  function test_codexUsage_noLimits() {
    var r = ModelUsage.codexUsage({}, "");
    compare(r.primary.percent, -1);
    compare(r.secondary.percent, -1);
    compare(r.todayTotalTokens, 0);
  }

  function test_parseGeminiSessions() {
    var content = [JSON.stringify({
                                    type: "user"
                                  }), JSON.stringify({
                                                       type: "gemini",
                                                       model: "gemini-2.5-pro",
                                                       tokens: {
                                                         total: 100
                                                       }
                                                     }), JSON.stringify({
                                                                          type: "user"
                                                                        }), JSON.stringify({
                                                                                             type: "gemini",
                                                                                             tokens: {
                                                                                               total: 50
                                                                                             }
                                                                                           }), "{broken"].join("\n");
    var r = ModelUsage.parseGeminiSessions(content);
    compare(r.prompts, 2);
    compare(r.tokens, 150);
    compare(r.tokensByModel["gemini-2.5-pro"], 100);
    compare(r.tokensByModel["gemini"], 50);
  }

  function test_parseCopilotUsage_paid() {
    var r = ModelUsage.parseCopilotUsage({
                                           copilot_plan: "individual",
                                           quota_reset_date: "2026-02-01",
                                           quota_snapshots: {
                                             premium_interactions: {
                                               percent_remaining: 75
                                             },
                                             chat: {
                                               percent_remaining: 100
                                             }
                                           }
                                         });
    compare(r.tier, "Individual");
    fuzzyCompare(r.primary.percent, 0.25, 1e-9);
    compare(r.primary.kind, "premium");
    compare(r.primary.params.percent, 25);
    compare(r.secondary.percent, 0);
    verify(r.primary.resetAt !== "");
  }

  function test_parseCopilotUsage_free() {
    var r = ModelUsage.parseCopilotUsage({
                                           limited_user_quotas: {
                                             chat: 40,
                                             completions: 1000
                                           },
                                           monthly_quotas: {
                                             chat: 50,
                                             completions: 2000
                                           }
                                         });
    fuzzyCompare(r.primary.percent, 0.2, 1e-9);
    compare(r.primary.kind, "chat-count");
    compare(r.primary.params.used, 10);
    compare(r.secondary.kind, "completions-count");
    fuzzyCompare(r.secondary.percent, 0.5, 1e-9);
  }

  function test_parseOpenRouterKey() {
    var withLimit = ModelUsage.parseOpenRouterKey({
                                                    usage_weekly: 5,
                                                    limit: 20,
                                                    is_free_tier: false
                                                  });
    fuzzyCompare(withLimit.primary.percent, 0.25, 1e-9);
    compare(withLimit.primary.kind, "spending");
    compare(withLimit.primary.params.limit, "20.00");
    verify(!withLimit.freeTier);

    var budget = ModelUsage.parseOpenRouterKey({
                                                 usage_weekly: 3,
                                                 limit_remaining: 1
                                               });
    compare(budget.primary.kind, "budget");
    fuzzyCompare(budget.primary.percent, 0.75, 1e-9);

    var none = ModelUsage.parseOpenRouterKey({
                                               is_free_tier: true
                                             });
    compare(none.primary.kind, "no-limit");
    compare(none.primary.percent, 0);
    verify(none.freeTier);
  }

  function test_aggregateOpenRouterActivity() {
    var days = ["2026-01-01", "2026-01-02"];
    var r = ModelUsage.aggregateOpenRouterActivity(days, {
                                                     "2026-01-01": [
                                                       {
                                                         model: "a",
                                                         requests: 2,
                                                         prompt_tokens: 10,
                                                         completion_tokens: 5
                                                       }
                                                     ],
                                                     "2026-01-02": [
                                                       {
                                                         model: "a",
                                                         requests: 1,
                                                         prompt_tokens: 1,
                                                         completion_tokens: 1
                                                       },
                                                       {
                                                         model: "b",
                                                         requests: 3,
                                                         prompt_tokens: 4,
                                                         completion_tokens: 0
                                                       }
                                                     ]
                                                   });
    compare(r.recentDays.length, 2);
    compare(r.recentDays[0].messageCount, 2);
    compare(r.todayPrompts, 4);
    compare(r.todayTotalTokens, 6);
    compare(r.todayTokensByModel["b"], 4);
    compare(r.modelUsage["a"].inputTokens, 11);
  }

  function test_resolveApiKey() {
    compare(ModelUsage.resolveApiKey(["", "env2"], "cfg"), "env2");
    compare(ModelUsage.resolveApiKey(["", ""], "cfg"), "cfg");
    compare(ModelUsage.resolveApiKey([], ""), "");
  }

  function test_barText() {
    var p = {
      todayPrompts: 12,
      todayTotalTokens: 3400,
      primary: {
        percent: 0.4
      },
      secondary: {
        percent: 0.05
      },
      statusText: ""
    };
    compare(ModelUsage.barText(p, "prompts"), "12");
    compare(ModelUsage.barText(p, "tokens"), "3.4K");
    compare(ModelUsage.barText(p, "usage"), "40%·5%");
    compare(ModelUsage.barText({
                                 primary: {
                                   percent: -1
                                 },
                                 secondary: {
                                   percent: -1
                                 },
                                 statusText: "Token expired"
                               }, "usage"), "Token expired");
    compare(ModelUsage.barText({
                                 primary: {
                                   percent: -1
                                 },
                                 statusText: ""
                               }, "usage"), "—");
    compare(ModelUsage.barText(null, "prompts"), "—");
  }

  function test_clampIndex() {
    compare(ModelUsage.clampIndex(2, 3), 2);
    compare(ModelUsage.clampIndex(3, 3), 0);
    compare(ModelUsage.clampIndex(1, 0), 0);
  }

  function test_entriesSorted() {
    compare(ModelUsage.entries({
                                 b: 1,
                                 a: 2
                               }), [
              {
                key: "a",
                value: 2
              },
              {
                key: "b",
                value: 1
              }
            ]);
    compare(ModelUsage.entries(null), []);
  }

  function test_settingsFromPlugin() {
    var s = ModelUsage.settingsFromPlugin({
                                            providers: {
                                              claude: {
                                                enabled: true
                                              },
                                              codex: {
                                                enabled: true
                                              },
                                              zen: {
                                                enabled: false,
                                                apiKey: "zk"
                                              },
                                              openrouter: {
                                                apiKey: "ok"
                                              }
                                            },
                                            refreshIntervalSec: 1000
                                          });
    verify(s.enabled.claude);
    verify(s.enabled.codex);
    verify(!s.enabled.gemini);
    compare(s.refreshIntervalSec, 300);
    compare(s.zenApiKey, "zk");
    compare(s.openrouterApiKey, "ok");
    compare(ModelUsage.settingsFromPlugin(null).refreshIntervalSec, 30);
  }

  function test_widgetFromPlugin() {
    compare(ModelUsage.widgetFromPlugin({
                                          barDisplayMode: "cycle",
                                          barCycleIntervalSec: 10,
                                          barMetric: "usage"
                                        }), {
              id: "ModelUsage",
              displayMode: "cycle",
              cycleIntervalSec: 10,
              metric: "usage"
            });
    compare(ModelUsage.widgetFromPlugin({
                                          barMetric: "bogus",
                                          barCycleIntervalSec: 0
                                        }), {
              id: "ModelUsage",
              displayMode: "active",
              cycleIntervalSec: 5,
              metric: "prompts"
            });
  }

  function test_migrateBarWidgets() {
    var sections = {
      left: [
        {
          id: "Clock"
        },
        {
          id: "plugin:model-usage"
        }
      ],
      center: [],
      right: [
        {
          id: "Tray"
        }
      ]
    };
    var r = ModelUsage.migrateBarWidgets(sections, {
                                           barMetric: "tokens"
                                         });
    compare(r.left[0].id, "Clock");
    compare(r.left[1].id, "ModelUsage");
    compare(r.left[1].metric, "tokens");
    compare(r.right[0].id, "Tray");
    compare(ModelUsage.migrateBarWidgets({
                                           left: [
                                             {
                                               id: "Clock"
                                             }
                                           ]
                                         }, {}), null);
  }

  // Regression: a bar that already had the native widget ended up with two of them
  function test_migrateBarWidgets_keepsExistingNative() {
    var r = ModelUsage.migrateBarWidgets({
                                           left: [
                                             {
                                               id: "plugin:model-usage"
                                             },
                                             {
                                               id: "ModelUsage",
                                               metric: "usage"
                                             }
                                           ],
                                           right: []
                                         }, {
                                           barMetric: "tokens"
                                         });
    compare(r.left.length, 1);
    compare(r.left[0].metric, "usage");
  }

  function test_migrateBarWidgets_onlyOneReplacement() {
    var r = ModelUsage.migrateBarWidgets({
                                           left: [
                                             {
                                               id: "plugin:model-usage"
                                             }
                                           ],
                                           right: [
                                             {
                                               id: "plugin:model-usage"
                                             }
                                           ]
                                         }, {});
    compare(r.left.length, 1);
    compare(r.left[0].id, "ModelUsage");
    compare(r.right.length, 0);
    compare(ModelUsage.migrateBarWidgets(null, {}), null);
  }
}
