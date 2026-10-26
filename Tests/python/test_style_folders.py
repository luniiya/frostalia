"""Every UI style is one folder in Styles/ with every piece the shared code loads from it.

Adding a style must only need a new folder: shared code may not name a style, and the
folder must hold its definition, every control skin and a qmldir for its own types.
"""
import pathlib
import re
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
STYLES = ROOT / "Styles"
SHARED = ("Commons", "Modules", "Services", "Widgets")


def style_dirs():
    return sorted(path for path in STYLES.iterdir() if path.is_dir() and not path.name.startswith(("_", ".")))


def required_skins():
    # Every NStyleSkin in the shared widgets loads Styles/<style>/<name>.qml
    names = set()
    for path in (ROOT / "Widgets").glob("*.qml"):
        source = path.read_text()
        for block in re.findall(r"NStyleSkin \{(.*?)\n\s*\}", source, re.S):
            names.update(re.findall(r'name: "(\w+)"', block))
    if (ROOT / "Widgets/NStyleCard.qml").exists():
        names.update(re.findall(r'name: "(\w+)"', (ROOT / "Widgets/NStyleCard.qml").read_text()))
    return names


def map_property(source, name):
    match = re.search(name + r": \(\{(.*?)\}\)", source, re.S)
    return dict(re.findall(r'"(\w+)": "([^"]+)"', match.group(1))) if match else {}


def token_keys(source):
    block = source[source.index("tokens: ({"):]
    first = re.search(r'\n(\s+)"\w+":', block)
    return set(re.findall(r'\n' + first.group(1) + r'"(\w+)":', block))


class StyleFolderTests(unittest.TestCase):
    def test_default_style_folder_exists(self):
        names = [path.name for path in style_dirs()]
        self.assertIn("material", names)
        self.assertGreaterEqual(len(names), 2)

    def test_every_style_has_every_skin(self):
        skins = required_skins()
        self.assertGreaterEqual(skins, {"Button", "IconButton", "Toggle", "SliderTrack", "SliderHandle",
                                        "QuickSliderTrack", "QuickSliderHandle", "Field", "Box", "TabButton", "Card"})
        for style in style_dirs():
            for skin in sorted(skins):
                with self.subTest(style=style.name, skin=skin):
                    self.assertTrue((style / (skin + ".qml")).is_file())

    def test_definitions_are_complete(self):
        material = (STYLES / "material/Definition.qml").read_text()
        # Optional looks: a style without frosted glass simply has none
        reference_tokens = token_keys(material) - {"frostedGlass"}
        reference_views = set(map_property(material, "views"))
        for style in style_dirs():
            definition = style / "Definition.qml"
            with self.subTest(style=style.name):
                self.assertTrue(definition.is_file())
                source = definition.read_text()
                self.assertRegex(source, r'labelKey: "options\.ui-style\.\w+"')
                self.assertIn("settingsDefaults: ({", source)
                self.assertLessEqual(reference_tokens, token_keys(source))
                views = map_property(source, "views")
                self.assertEqual(set(views), reference_views)
                for path in list(views.values()) + list(map_property(source, "barViews").values()):
                    self.assertTrue((ROOT / path).is_file(), path)
                kit = re.search(r'property string kit: "([^"]*)"', source).group(1)
                if kit:
                    self.assertTrue((ROOT / kit).is_file(), kit)

    def test_style_files_only_point_into_their_own_folder(self):
        for style in style_dirs():
            for path in style.rglob("*"):
                if path.suffix not in (".qml", ".js"):
                    continue
                for other in re.findall(r'Styles/(\w+)/', path.read_text()):
                    with self.subTest(path=str(path.relative_to(ROOT))):
                        self.assertEqual(other, style.name)

    def test_every_style_directory_lists_its_types(self):
        # Skins and faces are loaded by URL, so Quickshell never indexes these folders;
        # without a qmldir a skin can't use its siblings ("Key is not a type").
        for style in style_dirs():
            for directory in [style] + [path for path in style.rglob("*") if path.is_dir()]:
                files = sorted(path.name for path in directory.glob("*.qml"))
                if not files:
                    continue
                with self.subTest(directory=str(directory.relative_to(ROOT))):
                    qmldir = directory / "qmldir"
                    self.assertTrue(qmldir.is_file())
                    listed = sorted(re.findall(r"^\w+ [\d.]+ (\S+\.qml)$", qmldir.read_text(), re.M))
                    self.assertEqual(listed, files)

    def test_shared_code_does_not_name_a_style(self):
        for folder in SHARED:
            for path in (ROOT / folder).rglob("*.qml"):
                source = path.read_text()
                with self.subTest(path=str(path.relative_to(ROOT))):
                    self.assertNotRegex(source, r"\b(keycapControls|materialControls|materialLayout|keycapLayout)\b")
                    self.assertNotRegex(source, r'uiStyleId ===? "')
                    self.assertNotIn("Styles/keycap", source)
                    self.assertNotIn("Styles/material", source)

    def test_registry_loads_on_the_installed_qt(self):
        # Regression: `import Qt.labs.folderlistmodel 2.10` has no `status`, so the whole
        # shell failed to load at boot, and a .pragma library can't name `Component`.
        registry = (ROOT / "Commons/UiStyleRegistry.qml").read_text()
        self.assertRegex(registry, r"import Qt\.labs\.folderlistmodel\n")
        self.assertIn("onStatusChanged", registry)
        code = [line for line in (ROOT / "Helpers/UiStyles.js").read_text().splitlines()
                if not line.lstrip().startswith("//")]
        self.assertNotIn("Component.", "\n".join(code))


if __name__ == "__main__":
    unittest.main()
