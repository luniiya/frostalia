"""The Keycap style's bar faces stay registered, loadable and wired to their widgets."""
import pathlib
import re
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
STYLE = ROOT / "Styles/keycap"
FACES = STYLE / "Bar"

# Widgets that deliberately keep the plain keycap or draw nothing.
PLAIN = {"Spacer", "CustomButton"}


def bar_views(style="keycap"):
    source = (ROOT / "Styles" / style / "Definition.qml").read_text()
    block = source[source.index("barViews: ({"):]
    block = block[:block.index("})")]
    return dict(re.findall(r'"(\w+)": "([^"]+\.qml)"', block))


class KeycapStyleTests(unittest.TestCase):
    def test_material_cards_carry_the_keycap_skin(self):
        # Keycap draws on the Material layouts; these cards get their outline, keyline and
        # hard shadow from the style's Card skin (NStyleCard), and must stay opaque under it.
        for path in ("Modules/Panels/ControlCenter/MaterialTile.qml",
                     "Modules/Panels/ControlCenter/MaterialSliders.qml",
                     "Modules/Panels/ControlCenter/MaterialSystemMonitor.qml",
                     "Modules/Panels/ControlCenter/MaterialControlCenter.qml",
                     "Modules/Panels/ControlCenter/KdeConnectPill.qml",
                     "Modules/Cards/MaterialMediaCard.qml",
                     "Modules/Weather/WeatherSurface.qml",
                     "Widgets/NPill.qml",
                     "Modules/OSD/OSD.qml",
                     "Modules/Notification/Notification.qml",
                     "Modules/Toast/Toast.qml",
                     "Modules/EditDesktop/EditShelf.qml",
                     "Modules/EditDesktop/EditDesktopWindow.qml",
                     "Widgets/NMenuSurface.qml",
                     "Modules/Bar/Extras/TrayMenu.qml"):
            self.assertRegex((ROOT / path).read_text(), r"NStyleCard \{", path)
        weather = (ROOT / "Modules/Weather/WeatherSurface.qml").read_text()
        self.assertIn("Style.opaqueSurfaces ? Qt.tint(", weather)
        self.assertIn("kit.outline", (STYLE / "Card.qml").read_text())
        field = (STYLE / "Field.qml").read_text()
        self.assertNotIn("Qt.alpha(ShellColors.mSurface", field)

    def test_registered_faces_exist(self):
        views = bar_views()
        self.assertIn("Plate", views)
        for name, path in views.items():
            with self.subTest(face=name):
                self.assertTrue((ROOT / path).is_file(), path)
                self.assertTrue(path.startswith("Styles/keycap/Bar/"), path)

    def test_every_face_file_is_registered_or_shared(self):
        registered = {pathlib.Path(path).name for path in bar_views().values()}
        shared = {"KeycapFace.qml", "FaceKey.qml", "FaceGlyph.qml", "FaceSticker.qml", "FaceShape.qml"}
        for path in FACES.glob("*.qml"):
            with self.subTest(path=path.name):
                self.assertIn(path.name, registered | shared)

    def test_faces_do_not_import_shell_singletons(self):
        # Faces get everything through `kit` and `host` so tests can load them.
        for path in FACES.glob("*.qml"):
            source = path.read_text()
            with self.subTest(path=path.name):
                self.assertNotRegex(source, r"^import qs\.", )
                self.assertNotRegex(source, r"\b(ShellColors|Style|Settings|Icons)\.", path.name)

    def test_every_bar_widget_has_its_own_face(self):
        views = bar_views()
        for path in sorted((ROOT / "Modules/Bar/Widgets").glob("*.qml")):
            name = path.stem
            if name in PLAIN:
                continue
            source = path.read_text()
            used = set(re.findall(r'(?:faceView|view): (?:root\.\w+ \? )?"(\w+)"', source))
            with self.subTest(widget=name):
                self.assertTrue(used, f"{name} does not pick a style face")
                for face in used:
                    self.assertIn(face, views, f"{name} uses unregistered face {face}")
        # Tray deliberately sits on the plain keycap.
        self.assertIn('view: "Plate"', (ROOT / "Modules/Bar/Widgets/Tray.qml").read_text())

    def test_faces_are_mostly_unique(self):
        # Each widget has its own idea; only the shared Plate may repeat.
        counts = {}
        for path in (ROOT / "Modules/Bar/Widgets").glob("*.qml"):
            for face in set(re.findall(r'(?:faceView|view): (?:root\.\w+ \? )?"(\w+)"', path.read_text())):
                counts.setdefault(face, set()).add(path.stem)
        for face, widgets in counts.items():
            if face in ("Plate", "Battery"):
                continue
            with self.subTest(face=face):
                self.assertEqual(len(widgets), 1, f"{face} is shared by {sorted(widgets)}")

    def test_style_hosts_load_faces_through_nstyleface(self):
        for path in ("Modules/Bar/Extras/BarPillHorizontal.qml", "Modules/Bar/Extras/BarPillVertical.qml",
                     "Widgets/NIconButton.qml", "Modules/Bar/Extras/WorkspacePill.qml"):
            with self.subTest(path=path):
                self.assertIn("NStyleFace {", (ROOT / path).read_text())
        loader = (ROOT / "Widgets/NStyleFace.qml").read_text()
        self.assertIn("Style.barViewUrl(view)", loader)
        self.assertIn('"kit": Style.kit', loader)

    def test_desktop_widgets_do_not_depend_on_the_style(self):
        for path in (ROOT / "Modules/DesktopWidgets").glob("*.qml"):
            source = path.read_text()
            with self.subTest(path=path.name):
                self.assertNotIn("keycap", source.lower())
                self.assertNotIn("NStyleFace", source)

    def test_only_keycap_has_bar_faces(self):
        self.assertIn("Plate", bar_views("keycap"))
        self.assertEqual(bar_views("material"), {})

if __name__ == "__main__":
    unittest.main()
