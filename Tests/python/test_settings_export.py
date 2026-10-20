"""Settings export uses the native TOML format and a save-file dialog."""
import json
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]


class SettingsExportTests(unittest.TestCase):
    def test_export_replaces_json_clipboard_action(self):
        source = (ROOT / "Modules/Panels/Settings/Tabs/General/BasicsSubTab.qml").read_text()
        self.assertIn("fileMode: FileDialog.SaveFile", source)
        self.assertIn('defaultSuffix: "toml"', source)
        self.assertIn("Settings.exportSettings(SettingsExport.localPath(selectedFile))", source)
        self.assertIn('I18n.tr("panels.general.export-settings")', source)
        self.assertIn('icon: "download"', source)
        for removed in ("wl-copy", "JSON.stringify", 'icon: "json"', "copy-settings", "settings-copied"):
            self.assertNotIn(removed, source)

    def test_removed_json_action_strings_are_gone(self):
        english = json.loads((ROOT / "Assets/Translations/en.json").read_text())
        self.assertNotIn("copy-settings", english["panels"]["general"])
        self.assertNotIn("settings-copied", english["panels"]["general"])

    def test_export_uses_active_settings_without_modifying_live_store(self):
        source = (ROOT / "Commons/Settings.qml").read_text()
        self.assertIn("snapshot = QtObj2JS.qtObjectToPlainObject(root.data)", source)
        self.assertIn('[settingsStore.helper, "export", path]', source)
        self.assertIn("root.settingsExported(destination)", source)
        self.assertIn("root.settingsExportFailed(settingsExportErrors.text.trim())", source)

    def test_seed_paths_no_longer_include_json(self):
        source = (ROOT / "Helpers/SettingsPaths.js").read_text()
        self.assertNotIn(".json", source)
        self.assertNotIn("legacySettingsFile", source)
        self.assertIn('"defaults.toml"', source)
