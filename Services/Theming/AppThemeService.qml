pragma Singleton

import QtQuick
import Quickshell
import qs.Commons
import qs.Services.UI

Singleton {
  id: root

  // A wallpaper-based generate() waits for a fresh daemon query first
  property bool generatePending: false

  Connections {
    target: WallpaperService

    function onRefreshed() {
      if (root.generatePending) {
        root.generatePending = false;
        generateFromWallpaper();
      }
    }

    // When the wallpaper changes, regenerate theme if necessary
    function onWallpaperChanged(screenName, path) {
      // onRefreshed regenerates right after this
      if (root.generatePending)
        return;

      var effectiveMonitor = Settings.data.colorSchemes.monitorForColors;
      if (effectiveMonitor === "" || effectiveMonitor === undefined) {
        effectiveMonitor = Screen.name;
      }

      if (screenName !== effectiveMonitor)
        return;

      if (Settings.data.colorSchemes.useWallpaperColors) {
        generateFromWallpaper();
      } else if (ColorSchemeService.lastPredefinedSchemeData) {
        // Regenerate templates only; skip applyScheme so colors.json and scheme reload stay untouched
        // when outputs are unchanged (see template processor skip-identical writes).
        generateFromPredefinedScheme(ColorSchemeService.lastPredefinedSchemeData);
      } else {
        ColorSchemeService.applyScheme(Settings.data.colorSchemes.predefinedScheme);
      }
    }
  }

  Connections {
    target: Settings.data.colorSchemes
    function onDarkModeChanged() {
      Logger.d("AppThemeService", "Detected dark mode change");
      generate();
    }
    function onMonitorForColorsChanged() {
      if (Settings.data.colorSchemes.useWallpaperColors) {
        Logger.d("AppThemeService", "Monitor for colors changed to:", Settings.data.colorSchemes.monitorForColors);
        generateFromWallpaper();
      }
    }
    function onGenerationMethodChanged() {
      Logger.d("AppThemeService", "Generation method changed to:", Settings.data.colorSchemes.generationMethod);
      generate();
    }
  }

  // PUBLIC FUNCTIONS
  function init() {
    Logger.i("AppThemeService", "Service started");
  }

  function generate() {
    if (Settings.data.colorSchemes.useWallpaperColors) {
      // The wallpaper may have just changed (e.g. `colorScheme refresh` from a wallpaper script)
      generatePending = true;
      WallpaperService.refresh();
    } else {
      // applyScheme will trigger template generation via schemeReader.onLoaded
      ColorSchemeService.applyScheme(Settings.data.colorSchemes.predefinedScheme);
    }
  }

  function generateFromWallpaper() {
    var effectiveMonitor = Settings.data.colorSchemes.monitorForColors;
    if (effectiveMonitor === "" || effectiveMonitor === undefined) {
      effectiveMonitor = Screen.name;
    }

    const wp = WallpaperService.getWallpaper(effectiveMonitor);
    if (!wp) {
      Logger.e("AppThemeService", "No wallpaper found for monitor:", effectiveMonitor);
      return;
    }
    const mode = Settings.data.colorSchemes.darkMode ? "dark" : "light";
    TemplateProcessor.processWallpaperColors(wp, mode);
  }

  function generateFromPredefinedScheme(schemeData) {
    Logger.i("AppThemeService", "Generating templates from predefined color scheme");
    const mode = Settings.data.colorSchemes.darkMode ? "dark" : "light";
    var effectiveMonitor = Settings.data.colorSchemes.monitorForColors;
    if (effectiveMonitor === "" || effectiveMonitor === undefined) {
      effectiveMonitor = Screen.name;
    }
    const wallpaperPath = WallpaperService.getWallpaper(effectiveMonitor) || "";
    TemplateProcessor.processPredefinedScheme(schemeData, mode, wallpaperPath);
  }
}
