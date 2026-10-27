pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.Power
import qs.Services.Theming

Singleton {
  id: root

  // Hook connections for automatic script execution
  Connections {
    target: Settings.data.colorSchemes
    function onDarkModeChanged() {
      executeDarkModeHook(Settings.data.colorSchemes.darkMode);
    }
  }

  Connections {
    target: TemplateProcessor
    function onColorsGenerated() {
      executeColorGenerationHook();
    }
  }

  // Track eco mode state for hooks
  property bool wasEcoModeEnabled: false

  Connections {
    target: PowerProfileService
    function onEcoModeChanged() {
      const isEnabled = PowerProfileService.ecoMode;

      // Detect enabled: was disabled, now enabled
      if (!wasEcoModeEnabled && isEnabled) {
        executeEcoModeEnabledHook();
      }
      // Detect disabled: was enabled, now disabled
      if (wasEcoModeEnabled && !isEnabled) {
        executeEcoModeDisabledHook();
      }
      wasEcoModeEnabled = isEnabled;
    }
  }

  // Execute dark mode change hook
  function executeDarkModeHook(isDarkMode) {
    if (!Settings.data.hooks?.enabled) {
      return;
    }

    const script = Settings.data.hooks?.darkModeChange;
    if (!script || script === "") {
      return;
    }

    try {
      const command = script.replace(/\$1/g, isDarkMode ? "true" : "false");
      Quickshell.execDetached(["sh", "-lc", command]);
      Logger.d("HooksService", `Executed dark mode hook: ${command}`);
    } catch (e) {
      Logger.e("HooksService", `Failed to execute dark mode hook: ${e}`);
    }
  }

  // Execute eco mode enabled hook
  function executeEcoModeEnabledHook() {
    if (!Settings.data.hooks?.enabled) {
      return;
    }

    const script = Settings.data.hooks?.ecoModeEnabled;
    if (!script || script === "") {
      return;
    }

    try {
      Quickshell.execDetached(["sh", "-lc", script]);
    } catch (e) {
      Logger.e("HooksService", `Failed to execute eco mode enabled hook: ${e}`);
    }
  }

  // Execute eco mode disabled hook
  function executeEcoModeDisabledHook() {
    if (!Settings.data.hooks?.enabled) {
      return;
    }

    const script = Settings.data.hooks?.ecoModeDisabled;
    if (!script || script === "") {
      return;
    }

    try {
      Quickshell.execDetached(["sh", "-lc", script]);
    } catch (e) {
      Logger.e("HooksService", `Failed to execute eco mode disabled hook: ${e}`);
    }
  }

  // Execute color generation hook
  function executeColorGenerationHook() {
    if (!Settings.data.hooks?.enabled) {
      return;
    }

    const script = Settings.data.hooks?.colorGeneration;
    if (!script || script === "") {
      return;
    }

    try {
      const theme = Settings.data.colorSchemes.darkMode ? "dark" : "light";
      const command = script.replace(/\$1/g, theme);
      Quickshell.execDetached(["sh", "-lc", command]);
      Logger.d("HooksService", `Executed color generation hook: ${command}`);
    } catch (e) {
      Logger.e("HooksService", `Failed to execute color generation hook: ${e}`);
    }
  }

  // Blocking power hook infrastructure
  property var pendingPowerCallback: null

  Process {
    id: powerHookProcess
    onExited: (exitCode, exitStatus) => {
      if (exitCode !== 0) {
        Logger.w("HooksService", `Power hook failed with exit code ${exitCode}`);
      }

      if (pendingPowerCallback !== null) {
        const callback = pendingPowerCallback;
        pendingPowerCallback = null;
        callback();
      }
    }
  }

  function runPowerHook(script, callback) {
    pendingPowerCallback = callback;
    powerHookProcess.command = ["sh", "-lc", script];
    powerHookProcess.running = true;
  }

  function executeSessionHook(action, callback) {
    if (!Settings.data.hooks?.enabled) {
      callback();

      return;
    }

    const script = Settings.data.hooks?.session;
    if (!script) {
      callback();

      return;
    }

    Logger.i("HooksService", `Executing session hook for ${action}`);
    runPowerHook(`${script} ${action}`, callback);
  }

  // Execute startup hook
  function executeStartupHook() {
    if (!Settings.data.hooks?.enabled) {
      return;
    }

    const script = Settings.data.hooks?.startup;
    if (!script || script === "") {
      return;
    }

    try {
      Quickshell.execDetached(["sh", "-lc", script]);
      Logger.d("HooksService", `Executed startup hook: ${script}`);
    } catch (e) {
      Logger.e("HooksService", `Failed to execute startup hook: ${e}`);
    }
  }

  // Initialize the service
  function init() {
    Logger.i("HooksService", "Service started");
    Qt.callLater(() => {
      // Initialize eco mode state tracking
      wasEcoModeEnabled = PowerProfileService.ecoMode;
      // Execute startup hook
      executeStartupHook();
    });
  }
}
