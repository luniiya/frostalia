import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginL

  property var pluginApi: null

  property bool editCompactMode: pluginApi?.pluginSettings?.compactMode ?? pluginApi?.manifest?.metadata?.defaultSettings?.compactMode ?? false

  property string editIconColor: pluginApi?.pluginSettings?.iconColor ?? pluginApi?.manifest?.metadata?.defaultSettings?.iconColor ?? "none"

  property string editTextColor: pluginApi?.pluginSettings?.textColor ?? pluginApi?.manifest?.metadata?.defaultSettings?.textColor ?? "none"

  property int editWorkMinutes: pluginApi?.pluginSettings?.pomodoroWorkMinutes ?? 50
  property int editBreakMinutes: pluginApi?.pluginSettings?.pomodoroBreakMinutes ?? 10

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("Timer", "Cannot save: pluginApi is null");
      return;
    }

    if (root.editWorkMinutes !== pluginApi.mainInstance?.pmWorkMinutes || root.editBreakMinutes !== pluginApi.mainInstance?.pmBreakMinutes)
      pluginApi.mainInstance?.pomodoroPause();
    pluginApi.pluginSettings.pomodoroWorkMinutes = root.editWorkMinutes;
    pluginApi.pluginSettings.pomodoroBreakMinutes = root.editBreakMinutes;
    pluginApi.pluginSettings.compactMode = root.editCompactMode;
    pluginApi.pluginSettings.iconColor = root.editIconColor;
    pluginApi.pluginSettings.textColor = root.editTextColor;

    pluginApi.saveSettings();
    Logger.i("Timer", "Settings saved successfully");
  }

  NSpinBox {
    label: pluginApi?.tr("pomodoro.work-duration-label")
    from: 1
    to: 180
    value: root.editWorkMinutes
    defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.pomodoroWorkMinutes ?? 50
    onValueChanged: root.editWorkMinutes = value
  }

  NSpinBox {
    label: pluginApi?.tr("pomodoro.break-duration-label")
    from: 1
    to: 180
    value: root.editBreakMinutes
    defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.pomodoroBreakMinutes ?? 10
    onValueChanged: root.editBreakMinutes = value
  }

  // Icon Color
  NColorChoice {
    label: I18n.tr("common.select-icon-color")
    description: I18n.tr("common.select-color-description")
    currentKey: root.editIconColor
    onSelected: key => root.editIconColor = key
  }

  // Text Color
  NColorChoice {
    currentKey: root.editTextColor
    onSelected: key => root.editTextColor = key
  }

  // Compact Mode
  NToggle {
    label: pluginApi?.tr("settings.compact-mode") || "Compact Mode"
    description: pluginApi?.tr("settings.compact-mode-desc") || "Hide the circular progress bar for a cleaner look"
    checked: root.editCompactMode
    onToggled: checked => root.editCompactMode = checked
    defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.compactMode ?? false
  }
}
