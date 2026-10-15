import QtQuick
import Quickshell
import "../../../Helpers/ModelUsageLogic.js" as ModelUsageLogic
import qs.Commons

// OpenCode Zen: validates the API key and lists models. Zen has no documented
// usage endpoint, so no rate limit is reported.
ModelUsageProvider {
  id: root

  providerId: "zen"
  providerName: "Zen"
  helpText: I18n.tr("model-usage.help.zen")
  primary: ModelUsageLogic.emptyLimit("unavailable")

  property string configuredKey: ""
  readonly property string apiKey: ModelUsageLogic.resolveApiKey([Quickshell.env("OPENCODE_ZEN_API_KEY") || "", Quickshell.env("OPENCODE_API_KEY") || "", Quickshell.env("ZEN_API_KEY") || ""], configuredKey)
  readonly property string apiBaseUrl: "https://opencode.ai/zen/v1"

  // "unknown", "checking", "valid" or "invalid"
  property string authState: "unknown"
  property string validatedKey: ""
  property int availableModels: 0

  Timer {
    interval: 10 * 60 * 1000
    running: root.enabled
    repeat: true
    onTriggered: root.fetchModels()
  }

  onEnabledChanged: refresh()
  onApiKeyChanged: {
    validatedKey = "";
    authState = apiKey === "" ? "unknown" : "checking";
    updateState();
    refresh();
  }
  Component.onCompleted: refresh()

  function updateState() {
    if (!apiKey) {
      statusText = I18n.tr("model-usage.status.api-key-required");
      tierLabel = "";
    } else if (authState === "invalid") {
      statusText = I18n.tr("model-usage.status.token-invalid");
      tierLabel = "";
    } else {
      statusText = "";
      tierLabel = authState === "valid" ? I18n.tr("model-usage.tier.key-valid") : "";
    }
    ready = apiKey !== "" && authState !== "invalid" && availableModels > 0;
  }

  function fetchModels() {
    const xhr = new XMLHttpRequest();
    xhr.open("GET", apiBaseUrl + "/models");
    if (apiKey)
      xhr.setRequestHeader("Authorization", "Bearer " + apiKey);
    xhr.onreadystatechange = function () {
      if (xhr.readyState !== XMLHttpRequest.DONE)
        return;
      root.availableModels = 0;
      if (xhr.status === 200) {
        try {
          root.availableModels = (JSON.parse(xhr.responseText).data || []).length;
        } catch (e) {
          Logger.w("ModelUsage", "Failed to parse Zen models:", e);
        }
      } else {
        Logger.w("ModelUsage", "Zen models request failed, status", xhr.status);
      }
      root.updateState();
    };
    xhr.send();
  }

  // A 1-token request: 401/403 with "invalid api key" means the key is rejected
  function validateKey() {
    const key = apiKey;
    const xhr = new XMLHttpRequest();
    xhr.open("POST", apiBaseUrl + "/responses");
    xhr.setRequestHeader("Authorization", "Bearer " + key);
    xhr.setRequestHeader("Content-Type", "application/json");
    xhr.onreadystatechange = function () {
      if (xhr.readyState !== XMLHttpRequest.DONE)
        return;
      root.validatedKey = key;
      if (xhr.status === 401 || xhr.status === 403)
        root.authState = String(xhr.responseText).toLowerCase().indexOf("invalid api key") !== -1 ? "invalid" : "unknown";
      else if (xhr.status >= 200 && xhr.status < 500)
        root.authState = "valid";
      else
        root.authState = "unknown";
      root.updateState();
    };
    xhr.send(JSON.stringify({
                              "model": "glm-5-free",
                              "input": "hi",
                              "max_output_tokens": 1
                            }));
  }

  function refresh() {
    if (!enabled)
      return;
    updateState();
    fetchModels();
    if (apiKey && (validatedKey !== apiKey || authState === "unknown" || authState === "checking"))
      validateKey();
  }
}
