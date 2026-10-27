"""The launcher core loads a per-style view, and every view implements its interface."""
import pathlib
import re
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
LAUNCHER = ROOT / "Modules/Panels/Launcher"


def launcher_views():
    views = {}
    for definition in sorted((ROOT / "Styles").glob("*/Definition.qml")):
        match = re.search(r'"launcher": "([^"]+\.qml)"', definition.read_text())
        if match:
            views[definition.parent.name] = match.group(1)
    return views


class LauncherViewTests(unittest.TestCase):
    def test_material_and_keycap_have_their_own_view(self):
        views = launcher_views()
        self.assertEqual(views.get("material"), "Modules/Panels/Launcher/MaterialLauncherView.qml")
        self.assertEqual(views.get("keycap"), "Styles/keycap/LauncherView.qml")
        for path in views.values():
            with self.subTest(path=path):
                self.assertTrue((ROOT / path).is_file())

    def test_core_loads_the_style_view(self):
        core = (LAUNCHER / "LauncherCore.qml").read_text()
        self.assertIn('surface: "launcher"', core)
        self.assertIn('"launcher": root', core)
        # The core holds no presentation of its own
        for widget in ("NTextInput", "NTabBar", "NListView", "NGridView", "NSlideSwapView"):
            self.assertNotIn(widget, core)
        self.assertNotIn("launcherDebug", core)

    def test_views_implement_the_core_interface(self):
        for name in ("Modules/Panels/Launcher/MaterialLauncherView.qml", "Styles/keycap/LauncherView.qml"):
            source = (ROOT / name).read_text()
            with self.subTest(view=name):
                self.assertIn("property var launcher", source)
                self.assertIn("readonly property var resultsView", source)
                for fn in ("focusSearch()", "swapResults(direction, apply)", "resetVisuals()", "selectedRowTop(target)"):
                    self.assertIn(f"function {fn}", source)
                # Keys go through the shared handler so navigation is identical
                self.assertIn("Keys.onPressed: event => root.launcher.handleKeyPress(event)", source)
                self.assertIn("onTextEdited: root.launcher.setQuery(text)", source)
                self.assertIn("LauncherEntryIcon {", source)

    def test_keycap_fills_are_opaque(self):
        # A hard shadow behind a translucent fill shows through as a black blob.
        source = (ROOT / "Styles/keycap/LauncherView.qml").read_text()
        for match in re.finditer(r"\b(fillColor|body|color): (.+)", source):
            value = match.group(2)
            with self.subTest(line=match.group(0)):
                self.assertNotIn("Qt.alpha(root.keyFill", value)
                self.assertNotIn("Qt.alpha(ShellColors.mSurface", value)
        self.assertIn("function solid(c)", source)

    def test_old_delegates_are_gone(self):
        self.assertFalse((LAUNCHER / "LauncherListDelegate.qml").exists())
        self.assertFalse((LAUNCHER / "LauncherGridDelegate.qml").exists())

    def test_inline_components_are_not_shadowed_at_the_use_site(self):
        # Redeclaring a component's property where it is used makes a second property:
        # the component kept reading its own `index` (always 0), so every Material mode
        # key was drawn as the first of its group and the last lost its round end.
        for path in launcher_views().values():
            source = (ROOT / path).read_text()
            for name, body in re.findall(r"^  component (\w+): \w+ \{\n(.*?)^  \}$", source, re.S | re.M):
                declared = set(re.findall(r"^    (?:required |readonly )?property \w+(?:<\w+>)? (\w+)", body, re.M))
                for use in re.finditer(r"\b" + name + r" \{\n", source):
                    indent = re.match(r"[ ]*", source[source.rfind("\n", 0, use.start()) + 1:]).group(0)
                    end = source.find("\n" + indent + "}", use.end())
                    own = set(re.findall(r"^" + indent + r"  (?:required |readonly )?property \w+(?:<\w+>)? (\w+)",
                                         source[use.end():end], re.M))
                    with self.subTest(path=path, component=name, line=source.count("\n", 0, use.start()) + 1):
                        self.assertEqual(own & declared, set())


if __name__ == "__main__":
    unittest.main()
