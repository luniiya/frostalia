"""Repository consistency checks (run with: python3 -m unittest discover -s Tests/python)."""

import json
import pathlib
import re
import subprocess
import sys
import unittest

import settings_defaults

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


class ShellColorTests(unittest.TestCase):
    def test_theme_singleton_has_an_unambiguous_name(self):
        # QtQuick exports its own Color singleton starting with Qt 6.12.
        self.assertFalse((ROOT / "Commons" / "Color.qml").exists())
        source = (ROOT / "Commons" / "ShellColors.qml").read_text(encoding="utf-8")
        self.assertIn("pragma Singleton", source)
        self.assertIn("property color mPrimary:", source)

    def test_widgets_do_not_resolve_the_qtquick_color_singleton(self):
        for path in qml_files():
            with self.subTest(file=str(path.relative_to(ROOT))):
                source = path.read_text(encoding="utf-8")
                self.assertNotRegex(source, r"\bColor\s*[.\[]")
                self.assertNotRegex(source, r"target:\s*Color\b")


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

        defaults = settings_defaults.defaults()
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

    def test_toolbar_vertical_spacing_matches_the_window_inset(self):
        source = (ROOT / "Modules/Panels/Settings/SettingsContent.qml").read_text(encoding="utf-8")
        layout = source.split("// Main UI", 1)[1].split("// Shared toolbar", 1)[0]
        # Center the toolbar between the top edge and the content pane in
        # both styles, including when interface scaling changes the inset.
        self.assertRegex(layout, r"spacing:\s*anchors\.margins\b")

    def test_profile_details_are_in_separate_horizontal_groups(self):
        source = (ROOT / "Modules/Panels/Settings/SettingsHome.qml").read_text(encoding="utf-8")
        row = source.split("id: profileRow", 1)[1]
        for name in ("profileName", "profileHost", "profileOs"):
            with self.subTest(group=name):
                before = row.split(f"id: {name}", 1)[0]
                self.assertIn(f"id: {name}", row)
                # Each group belongs directly to the same row, rather than
                # being nested in a shared column below the user name.
                self.assertEqual(before.count("{") - before.count("}"), 1)
        self.assertNotIn("profileCardWidth", source)

    def test_panel_mode_setting_is_gone(self):
        # A leftover read of the removed setting silently evaluates to undefined
        for path in list(qml_files()) + list((ROOT / "Helpers").glob("*.js")):
            if path.name == "Migration27.qml":
                continue
            with self.subTest(path=str(path.relative_to(ROOT))):
                self.assertNotIn("settingsPanelMode", path.read_text(encoding="utf-8"))
        defaults = settings_defaults.defaults()
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
        defaults = settings_defaults.defaults()
        self.assertNotIn("wallpaper", defaults)

    def test_only_theming_reads_the_wallpaper(self):
        users = {str(p.relative_to(ROOT)) for p in qml_files()
                 if "WallpaperService." in p.read_text(encoding="utf-8")}
        # The Edit Desktop card shows a copy of the wallpaper (the daemon draws the real one);
        # the wallpaper visualizer draws only a cut-out of its subject, and the shelf says
        # whether the wallpaper has one
        self.assertEqual(users, {"shell.qml", "Services/Theming/AppThemeService.qml", "Modules/EditDesktop/EditDesktopWindow.qml",
                                 "Modules/WallpaperVisualizer/WallpaperVisualizer.qml", "Modules/EditDesktop/EditShelf.qml"})


class PowerProfileLabelTests(unittest.TestCase):
    """The Material control center tile names the current profile instead of showing enabled/disabled."""

    def test_helper_translation_keys_exist(self):
        # The helper names keys the QML translation check cannot see
        english = json.loads((ROOT / "Assets/Translations/en.json").read_text())
        keys = set(re.findall(r'"(common\.[a-z-]+)"', (ROOT / "Helpers/PowerProfiles.js").read_text()))
        self.assertEqual(keys, {"common.power-saver", "common.balanced", "common.performance", "common.unknown"})
        for key in keys:
            with self.subTest(key=key):
                self.assertIsInstance(english["common"].get(key.split(".")[1]), str)

    def test_service_import_does_not_shadow_quickshell_power_profiles(self):
        # Importing the helper "as PowerProfiles" hides Quickshell's PowerProfiles singleton
        service = (ROOT / "Services/Power/PowerProfileService.qml").read_text()
        self.assertNotRegex(service, r'\bas PowerProfiles\b')
        self.assertIn("readonly property var powerProfiles: PowerProfiles", service)

    def test_material_tile_shows_the_profile_name(self):
        tile = (ROOT / "Modules/Panels/ControlCenter/MaterialShortcut.qml").read_text()
        self.assertRegex(tile, r'widgetId === "PowerProfile"\)\s*return PowerProfileService\.getLabel\(\);')


class LyricsWidgetTests(unittest.TestCase):
    """The desktop lyrics widget: registered, drawn by every style, fed by LyricsService."""

    def test_widget_is_registered_with_settings(self):
        registry = (ROOT / "Services/UI/DesktopWidgetRegistry.qml").read_text()
        self.assertIn('widgetsObj["Lyrics"] = lyricsComponent;', registry)
        self.assertIn('urlsObj["Lyrics"] = _widgetsDir + "DesktopLyrics.qml";', registry)
        self.assertIn('"Lyrics": "WidgetSettings/LyricsSettings.qml"', registry)
        self.assertTrue((ROOT / "Modules/DesktopWidgets/Widgets/DesktopLyrics.qml").exists())
        self.assertTrue((ROOT / "Modules/Panels/Settings/DesktopWidgets/WidgetSettings/LyricsSettings.qml").exists())

    def test_every_style_draws_lyrics(self):
        # The shared widget keeps the clock and the stack; each style's "lyrics" view draws them
        widget = (ROOT / "Modules/DesktopWidgets/Widgets/DesktopLyrics.qml").read_text()
        self.assertIn('surface: "lyrics"', widget)
        for definition in sorted((ROOT / "Styles").glob("*/Definition.qml")):
            with self.subTest(style=definition.parent.name):
                view = re.search(r'"lyrics": "([^"]+)"', definition.read_text())
                self.assertIsNotNone(view)
                self.assertTrue((ROOT / view.group(1)).exists())

    def test_rufin_token_stays_off_the_command_line(self):
        # Process command lines are visible to every user; the token goes in the environment
        service = (ROOT / "Services/Media/LyricsService.qml").read_text()
        commands = [c for c in re.findall(r"command: \[(.*)\]", service) if "curl" in c]
        self.assertEqual(len(commands), 2)
        for command in commands:
            with self.subTest(command=command):
                self.assertNotIn("rufin.token", command)
                self.assertIn("$RUFIN_TOKEN", command)
        self.assertEqual(service.count('"RUFIN_TOKEN": rufin.token'), 2)


    def test_clock_follows_the_players_own_position(self):
        # Regression: Quickshell runs a position on from the last report, so Rufin
        # stalling while it buffers left the lyrics seconds ahead
        service = (ROOT / "Services/Media/LyricsService.qml").read_text()
        widget = (ROOT / "Modules/DesktopWidgets/Widgets/DesktopLyrics.qml").read_text()
        self.assertIn('"org.mpris.MediaPlayer2.Player", "Position"', service)
        self.assertIn("Lyrics.busctlPosition(text)", service)
        self.assertIn("function onPositionSampled(position, at)", widget)


class EcoModeTests(unittest.TestCase):
    """Eco mode is the lite mode: power saver forces it on, other profiles (Performance included) leave it to the user's toggle."""

    def test_performance_profile_does_not_drive_the_shell(self):
        pattern = re.compile(r"frostaliaPerformance|PowerProfile\.Performance\b.*(ecoMode|EcoMode)")
        for path in qml_files():
            if path.parent.name == "Migrations":
                continue
            with self.subTest(path=str(path.relative_to(ROOT))):
                self.assertIsNone(pattern.search(path.read_text(encoding="utf-8")))

    def test_eco_mode_is_forced_by_power_saver_only(self):
        service = (ROOT / "Services" / "Power" / "PowerProfileService.qml").read_text(encoding="utf-8")
        self.assertIn("EcoMode.forced(available, profile, PowerProfile.PowerSaver)", service)
        self.assertIn("Settings.data.ecoMode.enabled", service)

    def test_toggle_is_reachable(self):
        ipc = (ROOT / "Services" / "Control" / "IPCService.qml").read_text(encoding="utf-8")
        self.assertIn('target: "ecoMode"', ipc)
        registry = (ROOT / "Services" / "UI" / "ControlCenterWidgetRegistry.qml").read_text(encoding="utf-8")
        self.assertIn('"EcoMode": ecoModeComponent', registry)
        self.assertTrue((ROOT / "Modules" / "Panels" / "ControlCenter" / "Widgets" / "EcoMode.qml").exists())

    def test_bar_widget_is_registered_with_a_keycap_face(self):
        registry = (ROOT / "Services" / "UI" / "BarWidgetRegistry.qml").read_text(encoding="utf-8")
        self.assertIn('"EcoMode": ecoModeComponent', registry)
        self.assertTrue((ROOT / "Modules" / "Bar" / "Widgets" / "EcoMode.qml").exists())
        keycap = (ROOT / "Styles" / "keycap" / "Definition.qml").read_text(encoding="utf-8")
        self.assertIn('"EcoMode": "Styles/keycap/Bar/EcoModeFace.qml"', keycap)

    def test_control_center_shows_the_toggle_by_default(self):
        right = [entry["id"] for entry in settings_defaults.lookup("controlCenter.shortcuts.right")]
        self.assertEqual(right[right.index("PowerProfile") + 1], "EcoMode")

    def test_old_toggle_widget_is_not_registered(self):
        self.assertNotIn("FrostaliaPerformance", (ROOT / "Assets" / "settings-widgets-default.json").read_text(encoding="utf-8"))


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
