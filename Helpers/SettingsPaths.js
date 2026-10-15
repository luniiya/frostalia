.pragma library

// Per-host settings file resolution. Kept free of QML/Quickshell dependencies
// so it can be unit tested (see Tests/tst_settingspaths.qml).
//
// Layout:
//   <configDir>/settings/<hostname>.toml   per-host settings (default)
//   <configDir>/settings.toml              shared seed for new hosts
//   <configDir>/settings.json              legacy JSON seed

var fallbackHostName = "default";

// Turn raw hostname output into a safe file name
function sanitizeHostName(raw) {
  var name = String(raw === undefined || raw === null ? "" : raw).split("\n")[0].trim();
  // Keep the usual hostname characters, replace anything that could escape the directory
  name = name.replace(/[^A-Za-z0-9._-]/g, "_").replace(/^\.+/, "");
  return name.length > 0 ? name : fallbackHostName;
}

function ensureTrailingSlash(dir) {
  dir = String(dir || "");
  return dir.length > 0 && dir[dir.length - 1] !== "/" ? dir + "/" : dir;
}

function settingsDir(configDir) {
  return ensureTrailingSlash(configDir) + "settings/";
}

function legacySettingsFile(configDir) {
  return ensureTrailingSlash(configDir) + "settings.json";
}

function hostSettingsFile(configDir, hostName) {
  return settingsDir(configDir) + sanitizeHostName(hostName) + ".toml";
}

// An explicit FROSTALIA_SETTINGS_FILE always wins over the per-host file
function resolveSettingsFile(envOverride, configDir, hostName) {
  if (envOverride && String(envOverride).length > 0)
    return String(envOverride);
  return hostSettingsFile(configDir, hostName);
}

// Prefer the host's previous JSON over shared seeds. Sources are never removed.
function seedFiles(configDir, hostName) {
  return [
    settingsDir(configDir) + sanitizeHostName(hostName) + ".json",
    ensureTrailingSlash(configDir) + "settings.toml",
    legacySettingsFile(configDir)
  ];
}
