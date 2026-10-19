"""Repository consistency checks (run with: python3 -m unittest discover -s Tests/python)."""

import json
import pathlib
import re
import subprocess
import sys
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
EN = ROOT / "Assets" / "Translations" / "en.json"
TR_CALL = re.compile(r'I18n\.tr[pu]?\(\s*"([^"]+)"')


def qml_files():
    for path in ROOT.rglob("*.qml"):
        if "Tests" not in path.relative_to(ROOT).parts:
            yield path


def lookup(tree, key):
    node = tree
    for part in key.split("."):
        if not isinstance(node, dict) or part not in node:
            return None
        node = node[part]
    return node


class TranslationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.en = json.loads(EN.read_text(encoding="utf-8"))

    def test_translation_files_are_valid_json(self):
        for path in sorted((ROOT / "Assets" / "Translations").glob("*.json")):
            with self.subTest(file=path.name):
                json.loads(path.read_text(encoding="utf-8"))

    def test_literal_keys_exist_in_english(self):
        missing = []
        for path in qml_files():
            for key in TR_CALL.findall(path.read_text(encoding="utf-8")):
                # Keys ending in "." are prefixes concatenated at runtime
                if key.endswith("."):
                    continue
                if not isinstance(lookup(self.en, key), str):
                    missing.append(f"{path.relative_to(ROOT)}: {key}")
        self.assertEqual(missing, [], "translation keys missing from en.json")

    def test_notch_strings_present(self):
        self.assertEqual(lookup(self.en, "options.bar.type-notch"), "Notch")
        self.assertIsNotNone(lookup(self.en, "panels.bar.appearance-notch-gap-label"))
        self.assertIsNotNone(lookup(self.en, "panels.bar.appearance-notch-gap-description"))


class SettingsSearchIndexTests(unittest.TestCase):
    def test_index_is_up_to_date(self):
        index = ROOT / "Assets" / "settings-search-index.json"
        before = index.read_bytes()
        try:
            subprocess.run([sys.executable, str(ROOT / "Scripts" / "dev" / "build-settings-search-index.py")],
                           cwd=ROOT, check=True, capture_output=True)
            after = index.read_bytes()
        finally:
            index.write_bytes(before)
        self.assertEqual(before, after, "run Scripts/dev/build-settings-search-index.py and commit the result")

    def test_interface_scaling_is_in_general_basics(self):
        entries = json.loads((ROOT / "Assets" / "settings-search-index.json").read_text(encoding="utf-8"))
        scaling = [entry for entry in entries
                   if entry["labelKey"] == "panels.user-interface.scaling-label"]
        self.assertEqual(len(scaling), 1)
        self.assertEqual(scaling[0]["tabLabel"], "common.general")
        self.assertEqual(scaling[0]["tab"], 0)
        self.assertEqual(scaling[0]["subTab"], 0)
        self.assertEqual(scaling[0]["widget"], "NValueSlider")

    def test_index_keys_exist_in_english(self):
        en = json.loads(EN.read_text(encoding="utf-8"))
        entries = json.loads((ROOT / "Assets" / "settings-search-index.json").read_text(encoding="utf-8"))
        for entry in entries:
            for field in ("labelKey", "descriptionKey"):
                key = entry.get(field)
                if key:
                    with self.subTest(key=key):
                        self.assertIsInstance(lookup(en, key), str)


class SettingsSchemaTests(unittest.TestCase):
    def test_bar_type_options_match_settings_comment(self):
        settings = (ROOT / "Commons" / "Settings.qml").read_text(encoding="utf-8")
        tab = (ROOT / "Modules" / "Panels" / "Settings" / "Tabs" / "Bar" / "AppearanceSubTab.qml").read_text(encoding="utf-8")
        comment = re.search(r'property string barType: "\w+" // (.*)', settings).group(1)
        documented = set(re.findall(r'"(\w+)"', comment))
        offered = set(re.findall(r'"key": "(\w+)",\s*"name": I18n\.tr\("options\.bar\.type-', tab))
        self.assertEqual(documented, offered)
        self.assertIn("notch", offered)

    def test_notch_gap_default(self):
        settings = (ROOT / "Commons" / "Settings.qml").read_text(encoding="utf-8")
        self.assertRegex(settings, r"property int notchGap: \d+")

    def test_internal_lock_screen_is_removed(self):
        self.assertFalse((ROOT / "Modules" / "LockScreen").exists())
        self.assertFalse((ROOT / "Modules" / "Panels" / "Settings" / "Tabs" / "LockScreen").exists())
        shell = (ROOT / "shell.qml").read_text(encoding="utf-8")
        settings = (ROOT / "Modules" / "Panels" / "Settings" / "SettingsContent.qml").read_text(encoding="utf-8")
        self.assertNotIn("LockScreen", shell)
        self.assertNotIn("LockScreen", settings)
        self.assertIn("lockScreen", ipc_handlers())

        defaults = json.loads((ROOT / "Assets" / "settings-default.json").read_text(encoding="utf-8"))
        self.assertNotIn("lockTimeout", defaults["idle"])
        self.assertNotIn("lockOnSuspend", defaults["general"])
        self.assertNotIn("screenLock", defaults["hooks"])
        self.assertEqual(defaults["general"]["lockCommand"], "hyprlock")
        self.assertIn("lock", [option["action"] for option in defaults["sessionMenu"]["powerOptions"]])


class TrayWidgetDefaultsTests(unittest.TestCase):
    def test_colorize_style_default_matches_registry(self):
        registry = (ROOT / "Services" / "UI" / "BarWidgetRegistry.qml").read_text(encoding="utf-8")
        tray = re.search(r'"Tray": \{(.*?)\}', registry, re.S).group(1)
        registry_default = re.search(r'"colorizeStyle": "(\w+)"', tray).group(1)
        defaults = json.loads((ROOT / "Assets" / "settings-widgets-default.json").read_text(encoding="utf-8"))
        self.assertEqual(defaults["bar"]["Tray"]["colorizeStyle"], registry_default)
        helper = (ROOT / "Helpers" / "TrayIcon.js").read_text(encoding="utf-8")
        self.assertIn(f'"{registry_default}"', re.search(r"var colorizeStyles = \[(.*?)\]", helper).group(1))


def ipc_handlers():
    """Map each IpcHandler target in IPCService.qml to its source block."""
    source = (ROOT / "Services" / "Control" / "IPCService.qml").read_text(encoding="utf-8")
    handlers = {}
    for block in source.split("IpcHandler {")[1:]:
        target = re.search(r'target: "(\w+)"', block)
        if target:
            handlers[target.group(1)] = block
    return handlers


class IpcTests(unittest.TestCase):
    def test_color_scheme_refresh_regenerates_theme(self):
        block = ipc_handlers()["colorScheme"]
        body = re.search(r"function refresh\(\)\s*\{(.*?)\n    \}", block, re.S)
        self.assertIsNotNone(body, "colorScheme.refresh() missing")
        self.assertIn("AppThemeService.generate()", body.group(1))

    def test_model_usage_handlers_exist(self):
        block = ipc_handlers()["modelUsage"]
        self.assertIn('getPanel("modelUsagePanel"', block)
        self.assertRegex(block, r"function refresh\(\)")

    def test_plain_settings_ipc_opens_home_and_explicit_tabs_remain_available(self):
        block = ipc_handlers()["settings"]
        self.assertIn("SettingsPanelService.openHome()", block)
        self.assertIn("SettingsPanelService.toggleHome()", block)
        self.assertIn("root._settingsOpen(parsed.tab, parsed.subTab)", block)

    def test_ui_style_ipc_uses_the_profile_switch_path(self):
        block = ipc_handlers()["uiStyle"]
        self.assertIn("return Settings.setUiStyle(style)", block)
        self.assertIn("function get(): string", block)
        self.assertIn("function list(): string", block)
        self.assertNotIn("Settings.data.ui.style =", block)

    def test_dark_mode_handlers_still_exist(self):
        block = ipc_handlers()["darkMode"]
        for name in ("toggle", "setDark", "setLight"):
            with self.subTest(name=name):
                self.assertRegex(block, rf"function {name}\(\)")


class BarWidgetRegistryTests(unittest.TestCase):
    REGISTRY = ROOT / "Services" / "UI" / "BarWidgetRegistry.qml"

    def block(self, name):
        source = self.REGISTRY.read_text(encoding="utf-8")
        match = re.search(rf"property var {name}: \(\{{(.*?)\n\s*\}}\)", source, re.S)
        self.assertIsNotNone(match, f"{name} not found")
        return match.group(1)

    def test_every_widget_has_a_file(self):
        for widget_id in re.findall(r'"(\w+)":\s*\w+Component', self.block("widgets")):
            with self.subTest(widget=widget_id):
                self.assertTrue((ROOT / "Modules" / "Bar" / "Widgets" / f"{widget_id}.qml").exists())

    def test_widget_settings_files_exist(self):
        base = ROOT / "Modules" / "Panels" / "Settings" / "Bar"
        for widget_id, rel in re.findall(r'"(\w+)":\s*"([^"]+)"', self.block("widgetSettingsMap")):
            with self.subTest(widget=widget_id):
                self.assertTrue((base / rel).exists(), rel)

    def test_model_usage_panel_is_registered(self):
        main_screen = (ROOT / "Modules" / "MainScreen" / "MainScreen.qml").read_text(encoding="utf-8")
        self.assertIn('objectName: "modelUsagePanel-"', main_screen)


class BoxOutlineTests(unittest.TestCase):
    def test_outline_color_uses_outline_width(self):
        # Boxes using the outline color must also follow the outline thickness setting
        pattern = re.compile(
            r"border\.width: Style\.borderS\n\s*border\.color: Style\.boxBorderColor"
            r"|border\.color: Style\.boxBorderColor\n\s*border\.width: Style\.borderS"
        )
        for path in qml_files():
            with self.subTest(path=str(path.relative_to(ROOT))):
                self.assertIsNone(pattern.search(path.read_text(encoding="utf-8")))


class SettingsWindowTests(unittest.TestCase):
    """Settings always open in their own compositor window, never inside the bar."""

    def test_panel_mode_setting_is_gone(self):
        # A leftover read of the removed setting silently evaluates to undefined
        for path in list(qml_files()) + list((ROOT / "Helpers").glob("*.js")):
            if path.name == "Migration27.qml":
                continue
            with self.subTest(path=str(path.relative_to(ROOT))):
                self.assertNotIn("settingsPanelMode", path.read_text(encoding="utf-8"))
        defaults = json.loads((ROOT / "Assets" / "settings-default.json").read_text(encoding="utf-8"))
        self.assertNotIn("settingsPanelMode", defaults["ui"])

    def test_settings_panel_has_no_in_bar_content(self):
        source = (ROOT / "Modules" / "Panels" / "Settings" / "SettingsPanel.qml").read_text(encoding="utf-8")
        self.assertNotIn("panelContent", source)
        self.assertNotIn("SettingsContent", source)
        self.assertIn("openInWindow()", source)


class WallpaperTests(unittest.TestCase):
    """The system wallpaper daemon draws wallpapers; the shell only reads them for theming."""

    def test_no_wallpaper_management_left(self):
        pattern = re.compile(r"Settings\.data\.wallpaper\b|WallhavenService|wallpaperPanel|WallpaperSelector")
        for path in qml_files():
            if path.name == "Migration62.qml":
                continue
            with self.subTest(path=str(path.relative_to(ROOT))):
                self.assertIsNone(pattern.search(path.read_text(encoding="utf-8")))
        defaults = json.loads((ROOT / "Assets" / "settings-default.json").read_text(encoding="utf-8"))
        self.assertNotIn("wallpaper", defaults)

    def test_only_theming_reads_the_wallpaper(self):
        users = {str(p.relative_to(ROOT)) for p in qml_files()
                 if "WallpaperService." in p.read_text(encoding="utf-8")}
        self.assertEqual(users, {"shell.qml", "Services/Theming/AppThemeService.qml"})


class PerformanceModeTests(unittest.TestCase):
    """Performance mode follows the Performance power profile and has no toggle of its own."""

    def test_no_performance_toggle_left(self):
        pattern = re.compile(r"FrostaliaPerformance\b|toggleFrostaliaPerformance|setFrostaliaPerformance|frostaliaPerformanceMode\s*=")
        for path in qml_files():
            if path.parent.name == "Migrations":
                continue
            with self.subTest(path=str(path.relative_to(ROOT))):
                self.assertIsNone(pattern.search(path.read_text(encoding="utf-8")))
        for name in ("settings-default.json", "settings-widgets-default.json"):
            self.assertNotIn("FrostaliaPerformance", (ROOT / "Assets" / name).read_text(encoding="utf-8"))


class TooltipTests(unittest.TestCase):
    def test_no_unstyled_qt_tooltips(self):
        # Qt's attached ToolTip ignores the theme; it showed as a white box on control center tiles.
        for path in qml_files():
            with self.subTest(path=str(path.relative_to(ROOT))):
                self.assertNotRegex(path.read_text(encoding="utf-8"), r"\bToolTip\.(visible|text)\s*:")


class ShellNameTests(unittest.TestCase):
    def test_shell_name(self):
        settings = (ROOT / "Commons" / "Settings.qml").read_text(encoding="utf-8")
        self.assertIn('shellName: "frostalia"', settings)
        install = (ROOT / "install.sh").read_text(encoding="utf-8")
        self.assertIn("quickshell/frostalia\"", install)


if __name__ == "__main__":
    unittest.main()
