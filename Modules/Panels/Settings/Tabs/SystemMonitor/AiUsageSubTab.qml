import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginL
  Layout.fillWidth: true

  readonly property bool openrouterKeyFromEnv: (Quickshell.env("OPENROUTER_API_KEY") || "") !== ""
  readonly property bool zenKeyFromEnv: (Quickshell.env("OPENCODE_ZEN_API_KEY") || Quickshell.env("OPENCODE_API_KEY") || Quickshell.env("ZEN_API_KEY") || "") !== ""

  NText {
    text: I18n.tr("panels.system.ai-usage-intro")
    pointSize: Style.fontSizeS
    color: Color.mOnSurfaceVariant
    wrapMode: Text.WordWrap
    Layout.fillWidth: true
  }

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("panels.system.ai-usage-claude-label")
    description: I18n.tr("panels.system.ai-usage-claude-description")
    checked: Settings.data.modelUsage.claudeEnabled
    defaultValue: Settings.getDefaultValue("modelUsage.claudeEnabled")
    onToggled: checked => Settings.data.modelUsage.claudeEnabled = checked
  }

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("panels.system.ai-usage-codex-label")
    description: I18n.tr("panels.system.ai-usage-codex-description")
    checked: Settings.data.modelUsage.codexEnabled
    defaultValue: Settings.getDefaultValue("modelUsage.codexEnabled")
    onToggled: checked => Settings.data.modelUsage.codexEnabled = checked
  }

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("panels.system.ai-usage-copilot-label")
    description: I18n.tr("panels.system.ai-usage-copilot-description")
    checked: Settings.data.modelUsage.copilotEnabled
    defaultValue: Settings.getDefaultValue("modelUsage.copilotEnabled")
    onToggled: checked => Settings.data.modelUsage.copilotEnabled = checked
  }

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("panels.system.ai-usage-gemini-label")
    description: I18n.tr("panels.system.ai-usage-gemini-description")
    checked: Settings.data.modelUsage.geminiEnabled
    defaultValue: Settings.getDefaultValue("modelUsage.geminiEnabled")
    onToggled: checked => Settings.data.modelUsage.geminiEnabled = checked
  }

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("panels.system.ai-usage-openrouter-label")
    description: I18n.tr("panels.system.ai-usage-openrouter-description")
    checked: Settings.data.modelUsage.openrouterEnabled
    defaultValue: Settings.getDefaultValue("modelUsage.openrouterEnabled")
    onToggled: checked => Settings.data.modelUsage.openrouterEnabled = checked
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

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("panels.system.ai-usage-zen-label")
    description: I18n.tr("panels.system.ai-usage-zen-description")
    checked: Settings.data.modelUsage.zenEnabled
    defaultValue: Settings.getDefaultValue("modelUsage.zenEnabled")
    onToggled: checked => Settings.data.modelUsage.zenEnabled = checked
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
