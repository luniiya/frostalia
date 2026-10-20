import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../../../Helpers/ModelUsageOrder.js" as ModelUsageOrder
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginL
  Layout.fillWidth: true

  readonly property var labelKeys: ({
                                      "claude": "panels.system.ai-usage-claude-label",
                                      "codex": "panels.system.ai-usage-codex-label",
                                      "copilot": "panels.system.ai-usage-copilot-label",
                                      "gemini": "panels.system.ai-usage-gemini-label",
                                      "openrouter": "panels.system.ai-usage-openrouter-label",
                                      "zen": "panels.system.ai-usage-zen-label"
                                    })
  readonly property bool openrouterKeyFromEnv: (Quickshell.env("OPENROUTER_API_KEY") || "") !== ""
  readonly property bool zenKeyFromEnv: (Quickshell.env("OPENCODE_ZEN_API_KEY") || Quickshell.env("OPENCODE_API_KEY") || Quickshell.env("ZEN_API_KEY") || "") !== ""

  NText {
    text: I18n.tr("panels.system.ai-usage-intro")
    pointSize: Style.fontSizeS
    color: ShellColors.mOnSurfaceVariant
    wrapMode: Text.WordWrap
    Layout.fillWidth: true
  }

  NLabel {
    Layout.fillWidth: true
    label: I18n.tr("panels.system.ai-usage-providers-label")
    description: I18n.tr("panels.system.ai-usage-providers-description")
  }

  // Check to enable a provider, drag to set its tab order in the AI usage panel
  NReorderCheckboxes {
    Layout.fillWidth: true
    model: ModelUsageOrder.orderedIds(Settings.data.modelUsage.providerOrder).map(id => ({
                                                                                          "id": id,
                                                                                          "text": I18n.tr(root.labelKeys[id]),
                                                                                          "enabled": Settings.data.modelUsage[id + "Enabled"]
                                                                                        }))
    onItemToggled: (index, enabled) => {
                     const id = ModelUsageOrder.orderedIds(Settings.data.modelUsage.providerOrder)[index];
                     Settings.data.modelUsage[id + "Enabled"] = enabled;
                   }
    onItemsReordered: (fromIndex, toIndex) => {
                        Settings.data.modelUsage.providerOrder = ModelUsageOrder.moved(Settings.data.modelUsage.providerOrder, fromIndex, toIndex);
                      }
  }

  NTextInput {
    id: openrouterKeyInput
    visible: Settings.data.modelUsage.openrouterEnabled
    Layout.fillWidth: true
    label: I18n.tr("panels.system.ai-usage-openrouter-key-label")
    description: I18n.tr("panels.system.ai-usage-openrouter-key-description")
    enabled: !root.openrouterKeyFromEnv
    placeholderText: root.openrouterKeyFromEnv ? I18n.tr("panels.system.ai-usage-key-from-env") : ""
    text: root.openrouterKeyFromEnv ? "" : Settings.data.modelUsage.openrouterApiKey
    Component.onCompleted: {
      if (inputItem)
        inputItem.echoMode = TextInput.Password;
    }
    onEditingFinished: {
      if (!root.openrouterKeyFromEnv)
        Settings.data.modelUsage.openrouterApiKey = text;
    }
  }

  NTextInput {
    visible: Settings.data.modelUsage.zenEnabled
    Layout.fillWidth: true
    label: I18n.tr("panels.system.ai-usage-zen-key-label")
    description: I18n.tr("panels.system.ai-usage-zen-key-description")
    enabled: !root.zenKeyFromEnv
    placeholderText: root.zenKeyFromEnv ? I18n.tr("panels.system.ai-usage-key-from-env") : ""
    text: root.zenKeyFromEnv ? "" : Settings.data.modelUsage.zenApiKey
    Component.onCompleted: {
      if (inputItem)
        inputItem.echoMode = TextInput.Password;
    }
    onEditingFinished: {
      if (!root.zenKeyFromEnv)
        Settings.data.modelUsage.zenApiKey = text;
    }
  }

  NDivider {
    Layout.fillWidth: true
  }

  NSpinBox {
    label: I18n.tr("panels.system.ai-usage-refresh-label")
    description: I18n.tr("panels.system.ai-usage-refresh-description")
    from: 5
    to: 300
    stepSize: 5
    suffix: "s"
    value: Settings.data.modelUsage.refreshIntervalSec
    defaultValue: Settings.getDefaultValue("modelUsage.refreshIntervalSec")
    onValueChanged: Settings.data.modelUsage.refreshIntervalSec = value
  }
}
