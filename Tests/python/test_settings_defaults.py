"""Defaults in Commons/Settings.qml must match Assets/settings-default.json.

The JSON file backs Settings.getDefaultValue(), which every settings "reset"
button uses, so a missing or stale entry breaks resetting that setting.
"""

import json
import pathlib
import re
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
SETTINGS_QML = ROOT / "Commons" / "Settings.qml"
DEFAULTS_JSON = ROOT / "Assets" / "settings-default.json"

OPEN_OBJECT = re.compile(r"^\s*(?:property JsonObject )?(\w+): JsonObject \{")
SIMPLE_PROP = re.compile(r'^\s*property (bool|int|real|string) (\w+): (true|false|-?\d+(?:\.\d+)?|"[^"]*")\s*(?://.*)?$')

# Patched at runtime with machine-specific values, see Settings.qml Component.onCompleted
RUNTIME_PATCHED = {"general.avatarImage", "wallpaper.directory", "ui.fontDefault", "ui.fontFixed"}


def qml_defaults():
    """Yield (dotted.path, python value) for literal defaults inside the JsonAdapter."""
    text = SETTINGS_QML.read_text(encoding="utf-8")
    body = text[text.index("JsonAdapter {"):]
    stack = []  # (name, brace depth at which the object was opened)
    depth = 0
    for line in body.splitlines():
        match = OPEN_OBJECT.match(line)
        if match:
            stack.append((match.group(1), depth))
        prop = SIMPLE_PROP.match(line)
        if prop and depth >= 1:
            kind, name, raw = prop.groups()
            if raw in ("true", "false"):
                value = raw == "true"
            elif raw.startswith('"'):
                value = json.loads(raw)  # QML string escapes match JSON's
            else:
                value = float(raw)
            yield ".".join([s[0] for s in stack] + [name]), kind, value
        depth += line.count("{") - line.count("}")
        while stack and depth <= stack[-1][1]:
            stack.pop()
        if depth <= 0:
            break


def lookup(tree, path):
    node = tree
    for part in path.split("."):
        if not isinstance(node, dict) or part not in node:
            raise KeyError(path)
        node = node[part]
    return node


class SettingsDefaultsTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.defaults = json.loads(DEFAULTS_JSON.read_text(encoding="utf-8"))
        cls.qml = [d for d in qml_defaults() if d[0] not in RUNTIME_PATCHED]

    def test_parser_found_settings(self):
        paths = {p for p, _, _ in self.qml}
        self.assertGreater(len(paths), 100)
        self.assertIn("bar.barType", paths)
        self.assertIn("bar.notchGap", paths)

    def test_every_default_exists_in_json(self):
        missing = []
        for path, _, _ in self.qml:
            try:
                lookup(self.defaults, path)
            except KeyError:
                missing.append(path)
        self.assertEqual(missing, [], "add these to Assets/settings-default.json")

    def test_defaults_match(self):
        mismatched = []
        for path, kind, value in self.qml:
            try:
                actual = lookup(self.defaults, path)
            except KeyError:
                continue
            if kind in ("int", "real"):
                ok = isinstance(actual, (int, float)) and not isinstance(actual, bool) and abs(actual - value) < 1e-9
            else:
                ok = actual == value
            if not ok:
                mismatched.append(f"{path}: qml={value!r} json={actual!r}")
        self.assertEqual(mismatched, [])

    def test_session_menu_default_actions(self):
        options = lookup(self.defaults, "sessionMenu.powerOptions")
        enabled = [option for option in options if option["enabled"]]
        self.assertEqual([option["action"] for option in enabled],
                         ["lock", "shutdown", "reboot", "rebootToUefi"])
        self.assertEqual([option["keybind"] for option in enabled], ["1", "2", "3", "4"])
        self.assertTrue(all(option["keybind"] == "" for option in options if not option["enabled"]))
        self.assertEqual(len({option["action"] for option in options}), 8)
        text = SETTINGS_QML.read_text(encoding="utf-8")
        literal = re.search(r"property list<var> powerOptions: (\[[\s\S]*?\n      \])", text)
        self.assertIsNotNone(literal)
        self.assertEqual(json.loads(literal.group(1)), options)
        ui = (ROOT / "Modules/Panels/Settings/Tabs/SessionMenu/SessionMenuTab.qml").read_text(encoding="utf-8")
        ui_defaults = dict(re.findall(r'"id": "([^"\n]+)",\s*"text": [^\n]+\n\s*"enabled": (true|false)', ui))
        self.assertEqual(ui_defaults, {option["action"]: str(option["enabled"]).lower() for option in options})

    def test_screen_corners_black_by_default(self):
        self.assertIs(lookup(self.defaults, "general.forceBlackScreenCorners"), True)
        self.assertIn(("general.forceBlackScreenCorners", "bool", True), self.qml)


if __name__ == "__main__":
    unittest.main()
