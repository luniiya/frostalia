"""Run the actual Quickshell/Rust storage bridge without touching user settings."""
import os
import re
import pathlib
import shutil
import subprocess
import tempfile
import tomllib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]


def adapter_source():
    source = (ROOT / "Commons/Settings.qml").read_text()
    start = source.index("  JsonAdapter {")
    depth = 0
    for index in range(source.index("{", start), len(source)):
        depth += (source[index] == "{") - (source[index] == "}")
        if depth == 0:
            return source[start:index + 1].replace("id: adapter", "id: model")
    raise AssertionError("unclosed settings adapter")


@unittest.skipUnless(shutil.which("qs"), "Quickshell not installed")
class SettingsStoreTests(unittest.TestCase):
    def run_store(self, full_model=False):
        target = pathlib.Path(os.environ.get("CARGO_TARGET_DIR", ROOT / "Tools/settings/target"))
        helper = target / "debug/frostalia-settings"
        self.assertTrue(helper.exists(), "run cargo test for Tools/settings first")
        with tempfile.TemporaryDirectory(prefix="frostalia-store-") as directory:
            temp = pathlib.Path(directory)
            for folder in ("Commons", "Helpers", "Enums", "run"):
                (temp / folder).mkdir(mode=0o700)
            shutil.copy2(ROOT / "Commons/TomlSettingsStore.qml", temp / "Commons/TomlSettingsStore.qml")
            for name in ("QtObj2JS.js", "SettingsObject.js"):
                shutil.copy2(ROOT / "Helpers" / name, temp / "Helpers" / name)
            harness = (ROOT / "Tests/integration/settings-store.qml").read_text().replace('"../../Commons"', '"Commons"')
            if full_model:
                # Supply only the production enum, without starting the visual OSD.
                (temp / "Enums/OSD.qml").write_text("import QtQuick\nQtObject { enum Type { Volume, InputVolume, Brightness, LockKey } }\n")
                harness = 'import "Enums"\n' + harness
                start = harness.index("  JsonAdapter {")
                end = harness.index("\n  TomlSettingsStore", start)
                harness = harness[:start] + adapter_source() + "\n" + harness[end:]
            (temp / "shell.qml").write_text(harness)
            config = temp / "settings/test-host.toml"
            env = dict(os.environ, QT_QPA_PLATFORM="offscreen", XDG_RUNTIME_DIR=str(temp / "run"),
                       XDG_CACHE_HOME=str(temp / "cache"), FROSTALIA_TEST_CONFIG=str(config),
                       FROSTALIA_SETTINGS_HELPER=str(helper.resolve()))
            env.pop("WAYLAND_DISPLAY", None)
            result = subprocess.run(["qs", "--no-color", "-p", str(temp / "shell.qml")],
                                    env=env, capture_output=True, text=True, timeout=12)
            output = result.stdout + result.stderr
            self.assertIn("STORE_SUCCESS", output, output)
            self.assertNotIn("STORE_FAILURE", output, output)
            self.assertNotIn("TypeError", output, output)
            self.assertNotIn("ReferenceError", output, output)
            self.assertNotIn("Unable to assign", output, output)
            self.assertIn("# keep my comment", config.read_text())
            self.assertEqual(tomllib.loads(config.read_text())["bar"]["position"], "right")

    def test_first_install_ui_save_and_repeated_atomic_manual_edits(self):
        self.run_store()

    def test_full_production_settings_model_generates_and_reloads(self):
        self.run_store(full_model=True)

    def test_live_style_switches_and_external_profile_edits(self):
        target = pathlib.Path(os.environ.get("CARGO_TARGET_DIR", ROOT / "Tools/settings/target"))
        with tempfile.TemporaryDirectory(prefix="frostalia-ui-profiles-") as directory:
            temp = pathlib.Path(directory)
            (temp / "Commons").mkdir()
            (temp / "Helpers").mkdir()
            (temp / "run").mkdir(mode=0o700)
            shutil.copy2(ROOT / "Commons/TomlSettingsStore.qml", temp / "Commons/TomlSettingsStore.qml")
            for name in ("QtObj2JS.js", "SettingsObject.js", "UiStyleSettings.js", "UiStyles.js"):
                shutil.copy2(ROOT / "Helpers" / name, temp / "Helpers" / name)
            for definition in (ROOT / "Styles").glob("*/Definition.qml"):
                (temp / "Styles" / definition.parent.name).mkdir(parents=True)
                shutil.copy2(definition, temp / "Styles" / definition.parent.name / "Definition.qml")
            harness = (ROOT / "Tests/integration/ui-style-store.qml").read_text().replace('"../../Commons"', '"Commons"').replace('"../../Helpers/', '"Helpers/').replace('"../../Styles"', '"Styles"')
            # Exercise the production IPC methods against the real store in this
            # isolated shell, without starting unrelated system services.
            ipc_source = (ROOT / "Services/Control/IPCService.qml").read_text()
            handler = ipc_source.split('  IpcHandler {\n    target: "uiStyle"', 1)[1].split('\n  IpcHandler {', 1)[0]
            handler = '  IpcHandler {\n    target: "uiStyle"' + handler
            handler = handler.replace("Settings.setUiStyle(style)", "store.switchStyle(style)").replace("Settings.data.ui.style", "model.ui.style").replace("Style.uiStyleChoices", "[{key: 'keycap'}, {key: 'material'}]")
            harness = harness.replace("  JsonAdapter {", handler + "\n  JsonAdapter {", 1)
            (temp / "shell.qml").write_text(harness)
            config = temp / "settings/moon.toml"
            env = dict(os.environ, QT_QPA_PLATFORM="offscreen", XDG_RUNTIME_DIR=str(temp / "run"),
                       XDG_CACHE_HOME=str(temp / "cache"), FROSTALIA_TEST_CONFIG=str(config),
                       FROSTALIA_SETTINGS_HELPER=str((target / "debug/frostalia-settings").resolve()))
            env.pop("WAYLAND_DISPLAY", None)
            result = subprocess.run(["qs", "--no-color", "-p", str(temp / "shell.qml")],
                                    env=env, capture_output=True, text=True, timeout=12)
            output = result.stdout + result.stderr
            self.assertIn("STORE_SUCCESS", output, output)
            for failure in ("STORE_FAILURE", "TypeError", "ReferenceError", "Unable to assign"):
                self.assertNotIn(failure, output, output)
            host = tomllib.loads(config.read_text())
            self.assertNotIn("radiusRatio", host["general"])
            self.assertNotIn("fontDefault", host["ui"])
            self.assertEqual(host["general"]["scaleRatio"], 1.15)
            self.assertEqual(host["general"]["screenRadiusRatio"], 1.3)
            self.assertIn("# manual profile edit", (config.parent / "UI/material.toml").read_text())

    def test_real_settings_singleton_generates_hostname_config_on_first_install(self):
        root = ROOT
        version = int(re.search(r'readonly property int settingsVersion: (\d+)', (root/'Commons/Settings.qml').read_text()).group(1))
        with tempfile.TemporaryDirectory(prefix='frostalia-first-install-') as d:
         p=pathlib.Path(d)
         for folder in ['Commons','Helpers','Services/Frostalia','Services/UI','Modules/OSD','run']: (p/folder).mkdir(parents=True,exist_ok=True)
         (p/'run').chmod(0o700)
         for name in ['Settings.qml','TomlSettingsStore.qml','UiStyleRegistry.qml']: shutil.copy2(root/'Commons'/name,p/'Commons'/name)
         shutil.copytree(root/'Styles',p/'Styles')
         shutil.copytree(root/'Commons/Migrations',p/'Commons/Migrations')
         shutil.copytree(root/'Helpers',p/'Helpers',dirs_exist_ok=True)
         (p/'Assets').mkdir(); shutil.copy2(root/'Assets/settings-default.json',p/'Assets/settings-default.json')
         (p/'Commons/Logger.qml').write_text('pragma Singleton\nimport Quickshell\nSingleton { function i() {} function d() {} function w() {} function e(message) { console.error(message); } }')
         (p/'Services/Frostalia/PluginService.qml').write_text('pragma Singleton\nimport Quickshell\nSingleton { property bool initialized: false; property bool pluginsFullyLoaded: false }')
         (p/'Services/UI/Stub.qml').write_text('import QtQuick\nQtObject {}')
         (p/'Modules/OSD/OSD.qml').write_text('import QtQuick\nQtObject { enum Type { Volume, InputVolume, Brightness, LockKey } }')
         (p/'shell.qml').write_text('''import QtQuick
        import Quickshell
        import qs.Commons
        ShellRoot {
         Connections { target: Settings; function onSettingsSaved() {
          if (Settings.isLoaded && Settings.isFreshInstall && Settings.shouldOpenSetupWizard && Settings.data.settingsVersion === ''' + str(version) + ''') console.log("FIRST_INSTALL_SUCCESS", Settings.settingsFile);
          else console.error("FIRST_INSTALL_FAILURE");
          Qt.quit();
         } }
         Timer {running:true;interval:6000;onTriggered:{ console.error("FIRST_INSTALL_FAILURE timeout"); Qt.quit(); }}
        }''')
         env=dict(os.environ,QT_QPA_PLATFORM='offscreen',XDG_RUNTIME_DIR=str(p/'run'),XDG_CACHE_HOME=str(p/'cache'),FROSTALIA_CONFIG_DIR=str(p/'config'),FROSTALIA_CACHE_DIR=str(p/'cache'),FROSTALIA_SETTINGS_HELPER=str(root/'Tools/settings/target/debug/frostalia-settings'))
         for key in ['WAYLAND_DISPLAY','FROSTALIA_SETTINGS_FILE','FROSTALIA_DEBUG']:env.pop(key,None)
         r=subprocess.run(['qs','--no-color','-p',str(p/'shell.qml')],env=env,capture_output=True,text=True,timeout=12)
         self.assertIn('FIRST_INSTALL_SUCCESS', r.stdout+r.stderr, r.stdout+r.stderr)
         self.assertNotIn('FIRST_INSTALL_FAILURE', r.stdout+r.stderr)
         generated = list((p/'config/settings').glob('*.toml'))
         self.assertEqual(len(generated), 1)
         self.assertEqual(tomllib.loads(generated[0].read_text())['settingsVersion'], version)
         self.assertGreater(len(tomllib.loads(generated[0].read_text())), 20)
