"""All shell scrollbars share the same subtle opacity and interaction feedback."""
import pathlib
import re
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]


class ScrollbarStyleTests(unittest.TestCase):
    def test_all_explicit_scrollbars_use_shared_component(self):
        for directory in ("Widgets", "Modules"):
            for path in (ROOT / directory).rglob("*.qml"):
                if path.name == "NScrollBar.qml":
                    continue
                with self.subTest(path=str(path.relative_to(ROOT))):
                    self.assertNotRegex(path.read_text(), r"\bScrollBar\s*\{")

    def test_native_scrollviews_use_shared_vertical_scrollbar(self):
        for path in (ROOT / "Modules").rglob("*.qml"):
            source = path.read_text()
            if re.search(r"\bScrollView\s*\{", source):
                with self.subTest(path=str(path.relative_to(ROOT))):
                    self.assertIn("ScrollBar.vertical: NScrollBar {", source)

    def test_shared_scrollbar_animates_interaction_opacity(self):
        source = (ROOT / "Widgets/NScrollBar.qml").read_text()
        self.assertIn("opacity: ScrollbarStyle.opacity(hovered, pressed)", source)
        self.assertIn("Behavior on opacity", source)
        self.assertIn("duration: Style.animationFast", source)
