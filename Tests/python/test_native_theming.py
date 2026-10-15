"""Exercise the real Python-to-Rust bridge and preserve generated theme colors."""
import json
import os
from pathlib import Path
import struct
import sys
import tempfile
import unittest
from unittest.mock import patch
import zlib

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "Scripts/python/src/theming"))
from lib import Color, extract_palette, extract_source_color, generate_theme, source_color_to_rgb
from lib.image import ImageReadError, read_image, read_png
from lib.native import request


def png_bytes():
    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data))
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", 2, 1, 8, 2, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(b"\0\xff\0\0\0\x80\xff")) + chunk(b"IEND", b""))


class NativeThemingTests(unittest.TestCase):
    def test_final_dark_and_light_themes_match_python(self):
        fixtures = ROOT / "Tools/theming/tests/fixtures"
        pixels = json.loads((fixtures / "python-palettes.json").read_text())["images"]["warm_gradient"]
        for case in json.loads((fixtures / "python-themes.json").read_text()):
            with self.subTest(scheme=case["scheme"], mode=case["mode"]):
                scoring = {"vibrant": "chroma", "faithful": "count", "dysfunctional": "dysfunctional", "muted": "muted"}.get(case["scheme"])
                palette = (extract_palette(pixels, scoring=scoring) if scoring else
                           [Color.from_rgb(source_color_to_rgb(extract_source_color(pixels)))])
                self.assertEqual(generate_theme(palette, case["mode"], case["scheme"]), case["theme"])

    def test_png_fallback_without_imagemagick_and_unicode_path(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "wallpaper été with spaces.png"
            path.write_bytes(png_bytes())
            self.assertEqual(read_png(path), [(255, 0, 0), (0, 128, 255)])
            with patch.dict(os.environ, {"PATH": directory}):
                self.assertEqual(read_image(path), [(255, 0, 0), (0, 128, 255)])

    def test_imagemagick_resizes_image_for_extraction(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "wallpaper.png"
            path.write_bytes(png_bytes())
            for filter_name in ("Triangle", "Box"):
                self.assertEqual(len(read_image(path, filter_name)), 112 * 112)

    def test_invalid_images_and_requests_report_errors(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "broken.png"
            path.write_bytes(b"invalid image")
            with self.assertRaises(ImageReadError):
                read_image(path)
        for payload in ({"pixels": [[256, 0, 0]]}, {"pixels": [], "k": 257}, {"pixels": [], "scoring": "invalid"}):
            with self.subTest(payload=payload), self.assertRaises(RuntimeError):
                request("palette", **payload)
        with self.assertRaises(RuntimeError):
            request("unknown")

    def test_empty_inputs_and_missing_helper(self):
        self.assertEqual(extract_source_color([], fallback_color=0xFF123456), 0xFF123456)
        self.assertEqual(len(extract_palette([])), 5)
        with patch.dict(os.environ, {"FROSTALIA_THEMING_HELPER": "/missing/frostalia-theming"}):
            with self.assertRaisesRegex(RuntimeError, "Run ./install.sh"):
                extract_palette([(255, 0, 0)])


if __name__ == "__main__":
    unittest.main()
