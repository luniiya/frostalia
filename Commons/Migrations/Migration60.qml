import QtQuick
import Quickshell
import Quickshell.Io
import "../../Helpers/ModelUsageLogic.js" as ModelUsageLogic

QtObject {
  id: root

  // Same location as Settings.configDir + "plugins/model-usage/settings.json"
  readonly property string pluginSettingsPath: {
    let dir = Quickshell.env("FROSTALIA_CONFIG_DIR") || ((Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/frostalia");
    if (!dir.endsWith("/"))
      dir += "/";
    return dir + "plugins/model-usage/settings.json";
  }

  property FileView pluginSettingsFile: FileView {
    path: root.pluginSettingsPath
    blockAllReads: true
    printErrors: false
  }

  // The "model-usage" plugin became the built-in ModelUsage bar widget: replace the
  // plugin widget and import the plugin's provider settings
  function migrate(adapter, logger, rawJson) {
    logger.i("Settings", "Migrating settings to v60 (model-usage plugin → ModelUsage widget)");

    let plugin = null;
    try {
      const text = pluginSettingsFile.text();
      if (text)
        plugin = JSON.parse(text);
    } catch (e) {
      logger.w("Settings", "Could not read model-usage plugin settings:", e);
    }

    let replaced = false;
    const sections = ModelUsageLogic.migrateBarWidgets(rawJson?.bar?.widgets, plugin);
    if (sections) {
      for (const key of ["left", "center", "right"]) {
        if (sections[key] !== undefined)
          adapter.bar.widgets[key] = sections[key];
      }
      replaced = true;
    }

    const overrides = rawJson?.bar?.screenOverrides;
    if (Array.isArray(overrides)) {
      let overridesChanged = false;
      const newOverrides = overrides.map(o => {
        const widgets = o ? ModelUsageLogic.migrateBarWidgets(o.widgets, plugin) : null;
        if (!widgets)
          return o;
        overridesChanged = true;
        return Object.assign({}, o, {
                               "widgets": widgets
                             });
      });
      if (overridesChanged) {
        adapter.bar.screenOverrides = newOverrides;
        replaced = true;
      }
    }

    // Only import provider settings for people who used the plugin
    if (plugin && (replaced || rawJson?.modelUsage === undefined)) {
      const s = ModelUsageLogic.settingsFromPlugin(plugin);
      for (const id of ModelUsageLogic.providerIds)
        adapter.modelUsage[id + "Enabled"] = s.enabled[id];
      adapter.modelUsage.refreshIntervalSec = s.refreshIntervalSec;
      adapter.modelUsage.openrouterApiKey = s.openrouterApiKey;
      adapter.modelUsage.zenApiKey = s.zenApiKey;
      logger.i("Settings", "Imported model-usage plugin settings");
    }

    return true;
  }
}
