"""Wiring checks for the KDE Connect integration (Tools/kdeconnect, KdeConnectService, panel)."""

import json
import pathlib
import re
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
PANEL = ROOT / "Modules" / "Panels" / "KdeConnect"


def kdeconnect_sources():
    yield from PANEL.glob("*.qml")
    for rel in ("Services/Networking/KdeConnectService.qml", "Modules/Bar/Widgets/KdeConnect.qml",
                "Modules/Panels/ControlCenter/Widgets/KdeConnect.qml", "Helpers/KdeConnect.js"):
        yield ROOT / rel


class KdeConnectTests(unittest.TestCase):
    def test_disabled_by_default(self):
        defaults = json.loads((ROOT / "Assets" / "settings-default.json").read_text(encoding="utf-8"))
        self.assertIs(defaults["kdeConnect"]["enabled"], False)

    def test_every_page_has_a_file(self):
        content = (PANEL / "KdeConnectContent.qml").read_text(encoding="utf-8")
        block = re.search(r"pageFiles: \(\{(.*?)\}\)", content, re.S).group(1)
        pages = dict(re.findall(r'(\w+): "([^"]+\.qml)"', block))
        self.assertGreaterEqual(set(pages), {"messages", "thread", "compose", "notifications", "media", "remote", "files", "device"})
        for page, rel in pages.items():
            with self.subTest(page=page):
                self.assertTrue((PANEL / rel).is_file(), rel)
        # Pages that the home views push must be known to the stack.
        helper = (ROOT / "Helpers" / "KdeConnect.js").read_text(encoding="utf-8")
        for feature in re.findall(r'\{ id: "(\w+)", plugin: "\w+", icon', helper.split("var actions")[0]):
            with self.subTest(feature=feature):
                self.assertIn(feature, pages)

    def test_icons_exist(self):
        icons = (ROOT / "Commons" / "IconsTabler.qml").read_text(encoding="utf-8")
        known = set(re.findall(r'^\s*"([\w-]+)": "', icons, re.M))
        for path in kdeconnect_sources():
            source = path.read_text(encoding="utf-8")
            names = set(re.findall(r'\bicon:\s*"([a-z][\w-]*)"', source))
            names |= set(re.findall(r'"icon":\s*"([a-z][\w-]*)"', source))
            # Ternaries such as icon: playing ? "player-pause-filled" : "player-play-filled"
            names |= {n for pair in re.findall(r'icon[^\n]*\?\s*"([a-z][\w-]*)"\s*:\s*"([a-z][\w-]*)"', source) for n in pair}
            if path.suffix == ".js":
                names |= set(re.findall(r'return "((?:device|antenna)-[\w-]*[a-z0-9])"', source))
                names.add("antenna-bars-1")
                names.add("antenna-bars-5")
            for name in sorted(names):
                with self.subTest(path=path.name, icon=name):
                    self.assertIn(name, known)

    def test_panel_and_widgets_are_registered(self):
        main_screen = (ROOT / "Modules" / "MainScreen" / "MainScreen.qml").read_text(encoding="utf-8")
        self.assertIn('objectName: "kdeConnectPanel-"', main_screen)
        bar = (ROOT / "Services" / "UI" / "BarWidgetRegistry.qml").read_text(encoding="utf-8")
        self.assertIn('"KdeConnect": kdeConnectComponent', bar)
        cc = (ROOT / "Services" / "UI" / "ControlCenterWidgetRegistry.qml").read_text(encoding="utf-8")
        self.assertIn('"KdeConnect": kdeConnectComponent', cc)
        widgets = json.loads((ROOT / "Assets" / "settings-widgets-default.json").read_text(encoding="utf-8"))
        self.assertTrue(widgets["bar"]["KdeConnect"]["hideWhenOffline"])
        self.assertFalse(widgets["bar"]["KdeConnect"]["showUnread"], "bar widget shows only the battery by default")

    def test_helper_is_built_installed_and_tested(self):
        self.assertIn("Tools/kdeconnect/Cargo.toml", (ROOT / "Scripts" / "dev" / "run-tests.sh").read_text(encoding="utf-8"))
        self.assertIn("kdeconnect", (ROOT / "install.sh").read_text(encoding="utf-8"))
        service = (ROOT / "Services" / "Networking" / "KdeConnectService.qml").read_text(encoding="utf-8")
        self.assertIn('Quickshell.env("FROSTALIA_KDECONNECT_HELPER")', service)
        self.assertIn("/Tools/kdeconnect/target/release/frostalia-kdeconnect", service)

    def test_service_commands_exist_in_helper(self):
        # Every command the service sends must parse in Tools/kdeconnect/src/commands.rs.
        commands = (ROOT / "Tools" / "kdeconnect" / "src" / "commands.rs").read_text(encoding="utf-8")
        variants = re.search(r"pub enum Command \{(.*?)\n\}", commands, re.S).group(1)
        known = {name[0].lower() + name[1:] for name in re.findall(r"^\s{4}([A-Z]\w*)", variants, re.M)}
        service = (ROOT / "Services" / "Networking" / "KdeConnectService.qml").read_text(encoding="utf-8")
        used = set(re.findall(r'sendToDevice\("(\w+)"', service)) | set(re.findall(r'cmd: "(\w+)"', service))
        self.assertTrue(used)
        self.assertLessEqual(used, known, sorted(used - known))


if __name__ == "__main__":
    unittest.main()
