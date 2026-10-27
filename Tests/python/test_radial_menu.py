"""The desktop radial menu's saved item tree: defaults agree, labels are translated,
the tree survives the TOML store, and the menu is wired into the shell."""
import json
import os
import pathlib
import re
import subprocess
import tempfile
import tomllib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]


def qml_default_items():
    source = (ROOT / "Commons/Settings.qml").read_text()
    start = source.index("property JsonObject radialMenu: JsonObject {")
    literal_start = source.index("property list<var> items: [", start) + len("property list<var> items: ")
    depth = 0
    for index in range(literal_start, len(source)):
        depth += (source[index] == "[") - (source[index] == "]")
        if depth == 0:
            return json.loads(source[literal_start:index + 1])
    raise AssertionError("unclosed radialMenu.items literal")


def walk(items):
    for item in items:
        yield item
        yield from walk(item.get("children", []))


class RadialMenuTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.defaults = json.loads((ROOT / "Assets/settings-default.json").read_text())["radialMenu"]
        cls.english = json.loads((ROOT / "Assets/Translations/en.json").read_text())

    def lookup(self, key):
        node = self.english
        for part in key.split("."):
            self.assertIn(part, node, key)
            node = node[part]
        self.assertIsInstance(node, str, key)

    def test_qml_and_json_default_trees_match(self):
        self.assertEqual(qml_default_items(), self.defaults["items"])
        self.assertTrue(self.defaults["enabled"])

    def test_default_tree_covers_the_requested_actions(self):
        actions = [item["action"] for item in walk(self.defaults["items"])]
        for action in ("editDesktop", "settings", "wallpaper", "lock", "sessionMenu", "folder", "app",
                       "uiStyles", "darkMode", "nightLight", "doNotDisturb"):
            self.assertIn(action, actions)
        # TOML has no null: every field is a string, folders always carry children
        for item in walk(self.defaults["items"]):
            for key in ("action", "label", "labelKey", "icon", "arg"):
                self.assertIsInstance(item[key], str)
            self.assertEqual("children" in item, item["action"] == "folder")

    def test_every_label_key_is_translated(self):
        helper = (ROOT / "Helpers/RadialMenu.js").read_text()
        keys = set(re.findall(r'"labelKey": "([^"]+)"', helper))
        self.assertGreater(len(keys), 8)
        keys |= {item["labelKey"] for item in walk(self.defaults["items"]) if item["labelKey"]}
        settings_ui = (ROOT / "Modules/Panels/Settings/Tabs/RadialMenu/RadialMenuTab.qml").read_text()
        keys |= set(re.findall(r'I18n\.tr\("(radial-menu\.[^"]+)"', settings_ui))
        for key in sorted(keys):
            self.lookup(key)

    def test_every_action_is_run_by_the_menu(self):
        helper = (ROOT / "Helpers/RadialMenu.js").read_text()
        block = helper[helper.index("var actions = {"):helper.index("};", helper.index("var actions = {"))]
        menu = (ROOT / "Modules/RadialMenu/RadialMenu.qml").read_text()
        for action in re.findall(r'^  "(\w+)": \{', block, re.M):
            # Folders open rings; uiStyles is expanded into a folder of uiStyle items
            if action not in ("folder", "uiStyles"):
                self.assertIn(f'case "{action}":', menu, action)

    def test_service_expands_the_style_folder_from_every_style(self):
        service = (ROOT / "Services/UI/RadialMenuService.qml").read_text()
        self.assertIn("RadialMenu.expandItems(RadialMenu.normalizeItems(Settings.data.radialMenu.items), UiStyleRegistry.choices)", service)
        for definition in (ROOT / "Styles").glob("*/Definition.qml"):
            for key in re.findall(r'labelKey: "(options\.ui-style\.[a-z]+)"', definition.read_text()):
                self.lookup(key)

    def test_tree_round_trips_through_the_toml_store(self):
        target = pathlib.Path(os.environ.get("CARGO_TARGET_DIR", ROOT / "Tools/settings/target"))
        helper = target / "debug/frostalia-settings"
        if not helper.exists():
            self.skipTest("run cargo test for Tools/settings first")
        with tempfile.TemporaryDirectory(prefix="frostalia-radial-") as directory:
            config = pathlib.Path(directory) / "host.toml"
            request = json.dumps({"settings": {"radialMenu": self.defaults}, "baseline": None})
            subprocess.run([str(helper), "save", str(config)], input=request + "\n", text=True, check=True, capture_output=True)
            saved = tomllib.loads(config.read_text())
            self.assertEqual(saved["radialMenu"], self.defaults)

    def test_menu_is_wired_into_the_shell(self):
        shell = (ROOT / "shell.qml").read_text()
        self.assertIn("import qs.Modules.RadialMenu", shell)
        self.assertIn("RadialMenu {}", shell)
        menu = (ROOT / "Modules/RadialMenu/RadialMenu.qml").read_text()
        # Edit mode keeps right click for selecting widgets
        self.assertIn("enabled: !DesktopWidgetRegistry.editMode", menu)
        self.assertIn("DesktopWidgetRegistry.editMode = next.editing", menu)
        # The editor is its own settings tab, opened from the menu by "editRadialMenu"
        content = (ROOT / "Modules/Panels/Settings/SettingsContent.qml").read_text()
        self.assertIn("RadialMenuTab {}", content)
        self.assertIn('"id": SettingsPanel.Tab.RadialMenu', content)
        self.assertIn("SettingsPanelService.openToTab(SettingsPanel.Tab.RadialMenu", menu)
        settings_ui = (ROOT / "Modules/Panels/Settings/Tabs/RadialMenu/RadialMenuTab.qml").read_text()
        for key in ("enabled", "shape", "size", "opacity", "animations"):
            self.assertIn(f'defaultValue: Settings.getDefaultValue("radialMenu.{key}")', settings_ui)
            self.assertIn(f"Settings.data.radialMenu.{key} =", settings_ui)
        # Look preferences reach the menu
        service = (ROOT / "Services/UI/RadialMenuService.qml").read_text()
        self.assertIn("RadialMenu.visual(Style.uiStyleTokens.radialMenu, Settings.data.radialMenu)", service)

    def test_default_settings_folder_can_edit_the_menu(self):
        folder = next(item for item in self.defaults["items"] if item["labelKey"] == "radial-menu.items.settings")
        self.assertIn("editRadialMenu", [child["action"] for child in folder["children"]])

    def test_right_click_on_desktop_widgets_opens_the_menu(self):
        # Widget input regions sit above the background catcher; invisible widgets used to
        # swallow the right click. The layer forwards it for every widget outside edit mode.
        layer = (ROOT / "Modules/DesktopWidgets/DesktopWidgetsLayer.qml").read_text()
        start = layer.index("MouseArea {")
        catcher = layer[start:layer.index("\n  }\n", start)]
        self.assertIn("enabled: !root.editing", catcher)
        self.assertIn("acceptedButtons: Qt.RightButton", catcher)
        self.assertIn("RadialMenuService.openAt(root.screen, mouse.x, mouse.y)", catcher)
        self.assertIn("RadialMenuService.pointerReleased(mouse.x, mouse.y)", catcher)

    def test_search_index_lists_the_toggle(self):
        index = json.loads((ROOT / "Assets/settings-search-index.json").read_text())
        self.assertIn("radial-menu.settings.enabled-label", json.dumps(index))


if __name__ == "__main__":
    unittest.main()
