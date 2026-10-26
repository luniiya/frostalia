"""Scripts/dev/ui-screenshots.sh only calls IPC functions the shell defines."""
import os
import pathlib
import re
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "Scripts/dev/ui-screenshots.sh"


def ipc_functions():
    """{target: {function names}} for every IpcHandler in the tree."""
    handlers = {}
    for path in ROOT.rglob("*.qml"):
        if "Tests" in path.parts:
            continue
        source = path.read_text(errors="ignore")
        for match in re.finditer(r"IpcHandler\s*\{", source):
            depth, end = 0, match.end() - 1
            for end in range(match.end() - 1, len(source)):
                depth += (source[end] == "{") - (source[end] == "}")
                if depth == 0:
                    break
            body = source[match.end():end]
            target = re.search(r'target:\s*"([^"]+)"', body)
            if target:
                handlers.setdefault(target.group(1), set()).update(re.findall(r"function\s+(\w+)\s*\(", body))
    return handlers


class UiScreenshotsTest(unittest.TestCase):
    def setUp(self):
        self.source = SCRIPT.read_text()
        self.handlers = ipc_functions()

    def assertIpc(self, target, function):
        self.assertIn(target, self.handlers, f"no IpcHandler with target {target!r}")
        self.assertIn(function, self.handlers[target], f"{target} has no IPC function {function!r}")

    def test_shots_call_existing_ipc_functions(self):
        shots = re.findall(r'^\s*"(\w+)\|([@\w:-]*)\|(\w*)\|[^"]*"$', self.source, re.MULTILINE)
        self.assertGreater(len(shots), 10)
        for name, target, function in shots:
            with self.subTest(shot=name):
                if target.startswith("@"):
                    # Clicked bar widget: the button is the function
                    self.assertIn(function, ("left", "right", "middle"))
                    self.assertTrue((ROOT / f"Modules/Bar/Widgets/{target[1:]}.qml").exists(), target)
                # Plugin targets come from installed plugins; the script skips missing ones
                elif target and not target.startswith("plugin:"):
                    self.assertIpc(target, function)
                    if function == "openTab":
                        # Closed again through the window toggle
                        self.assertIpc(target, "toggle")

    def test_helper_calls_exist(self):
        for target, function in [("state", "panels"), ("state", "all"), ("uiStyle", "get"), ("uiStyle", "set"),
                                 ("darkMode", "setDark"), ("darkMode", "setLight"), ("volume", "increase"), ("toast", "send"),
                                 ("volume", "decrease"), ("state", "widgetRect"), ("state", "trayDrawerItemRect"), ("dock", "toggle")]:
            with self.subTest(call=f"{target} {function}"):
                self.assertIn(f"ipc {target} {function}", self.source)
                self.assertIpc(target, function)

    def test_settings_tabs_cover_every_tab_and_subtab(self):
        listed = dict(entry.split(":") for entry in re.search(r'SETTINGS_TABS="([^"]+)"', self.source).group(1).split())
        ipc = (ROOT / "Services/Control/IPCService.qml").read_text()
        tab_map = dict(re.findall(r'"(\w+)": SettingsPanel\.Tab\.(\w+)', ipc))
        enum = re.search(r"enum Tab \{([^}]+)\}", (ROOT / "Modules/Panels/Settings/SettingsPanel.qml").read_text()).group(1)
        tabs = set(re.findall(r"([A-Z]\w+)", enum))
        # Every tab is reachable over IPC and shot once
        self.assertEqual({tab_map[key] for key in listed}, tabs)
        for tab in tabs:
            self.assertIn(tab, tab_map.values(), f"no IPC name for settings tab {tab}")
        # Tab enum names that live in differently named folders
        folders = {"Location": "Region", "System": "SystemMonitor", "OSD": "Osd"}
        for key, count in listed.items():
            tab = tab_map[key]
            with self.subTest(tab=tab):
                folder = folders.get(tab, tab)
                path = ROOT / f"Modules/Panels/Settings/Tabs/{folder}/{folder}Tab.qml"
                if not path.exists():
                    path = ROOT / f"Modules/Panels/Settings/Tabs/{folder}Tab.qml"
                buttons = path.read_text().count("NTabButton {")
                self.assertEqual(int(count), max(1, buttons), f"{path.name} has {buttons} subtabs")

    def test_click_helper_is_executable(self):
        click = ROOT / "Scripts/dev/click.py"
        self.assertTrue(os.access(click, os.X_OK))
        self.assertIn('"$(dirname "$0")/click.py"', self.source)

    def test_documented_for_agents(self):
        self.assertIn("Scripts/dev/ui-screenshots.sh", (ROOT / "CLAUDE.md").read_text())


if __name__ == "__main__":
    unittest.main()
