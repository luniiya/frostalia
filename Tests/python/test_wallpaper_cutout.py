"""Wallpaper cut-outs: the separable-or-not decision, caching and the shell's wiring."""
import importlib.util
import json
import pathlib
import re
import subprocess
import sys
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "Scripts/python/src/wallpaper/wallpaper-cutout.py"

spec = importlib.util.spec_from_file_location("wallpaper_cutout", SCRIPT)
cutout = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cutout)


def stats(coverage, unsure):
    return {"coverage": coverage, "unsure": unsure}


class DecisionTests(unittest.TestCase):
    def test_mask_stats(self):
        self.assertEqual(cutout.mask_stats([0, 0, 255, 255]), stats(0.5, 0.0))
        self.assertEqual(cutout.mask_stats([128, 0, 0, 0]), stats(0.25, 0.25))
        self.assertEqual(cutout.mask_stats([]), stats(0.0, 0.0))

    def test_calibrated_wallpapers(self):
        # Numbers measured on the maintainer's wallpapers (isnet-anime, isnet-general-use)
        cases = {
            "girl in the wind": ({"anime": stats(0.215, 0.083), "general": stats(0.173, 0.27)}, "anime"),
            "manga page": ({"anime": stats(0.357, 0.4), "general": stats(0.031, 0.146)}, None),
            "jellyfish": ({"anime": stats(0.0, 0.0), "general": stats(0.182, 0.133)}, "general"),
            "neutron star": ({"anime": stats(0.0, 0.0), "general": stats(0.065, 0.041)}, "general"),
            "beach": ({"anime": stats(0.001, 0.05), "general": stats(0.017, 0.005)}, None),
            "city at night": ({"anime": stats(0.0, 0.0), "general": stats(0.002, 0.033)}, None),
            "close-up face": ({"anime": stats(0.9995, 0.0008), "general": stats(0.069, 0.205)}, None),
            "angel": ({"anime": stats(0.233, 0.068), "general": stats(0.202, 0.15)}, "anime"),
            "portrait": ({"anime": stats(0.618, 0.071), "general": stats(0.589, 0.133)}, "anime"),
        }
        for name, (candidates, expected) in cases.items():
            with self.subTest(name):
                self.assertEqual(cutout.pick(candidates), expected)

    def test_coverage_bounds(self):
        self.assertIsNone(cutout.score(stats(cutout.MIN_COVERAGE / 2, 0)))
        self.assertIsNone(cutout.score(stats(cutout.MAX_COVERAGE + 0.01, 0)))
        self.assertEqual(cutout.score(stats(0.5, 0.1)), 0.2)

    def test_animated_wallpapers_are_skipped(self):
        self.assertTrue(cutout.is_animated("/w/blue city.GIF"))
        self.assertTrue(cutout.is_animated("/w/loop.webp", frames=12))
        self.assertFalse(cutout.is_animated("/w/still.png"))


class CacheTests(unittest.TestCase):
    def test_key_follows_the_file_version(self):
        key = cutout.cache_key("/w/a.png", 1, 10)
        self.assertEqual(key, cutout.cache_key("/w/a.png", 1, 10))
        self.assertNotEqual(key, cutout.cache_key("/w/a.png", 2, 10))
        self.assertNotEqual(key, cutout.cache_key("/w/b.png", 1, 10))

    def test_stale_entries_drop_the_oldest(self):
        entries = {"a": 1, "b": 5, "c": 3, "d": 4}
        self.assertEqual(cutout.stale_entries(entries, keep=2), ["a", "c"])
        self.assertEqual(cutout.stale_entries(entries, keep=10), [])

    def test_cached_result_is_printed_without_rembg(self):
        with tempfile.TemporaryDirectory() as directory:
            wallpaper = pathlib.Path(directory) / "wall.png"
            wallpaper.write_bytes(b"not decoded")
            cache = pathlib.Path(directory) / "cache"
            cache.mkdir()
            stat = wallpaper.stat()
            record = {"source": str(wallpaper), "separable": False, "model": None, "image": "", "coverage": 0}
            (cache / (cutout.cache_key(str(wallpaper), stat.st_mtime_ns, stat.st_size) + ".json")).write_text(json.dumps(record))
            output = subprocess.run([sys.executable, str(SCRIPT), str(wallpaper), str(cache)],
                                    capture_output=True, text=True, check=True).stdout
            self.assertEqual(json.loads(output), record)

    def test_animated_wallpaper_needs_no_rembg(self):
        with tempfile.TemporaryDirectory() as directory:
            wallpaper = pathlib.Path(directory) / "loop.gif"
            wallpaper.write_bytes(b"GIF89a")
            output = subprocess.run([sys.executable, str(SCRIPT), str(wallpaper), directory + "/cache"],
                                    capture_output=True, text=True, check=True).stdout
            self.assertFalse(json.loads(output)["separable"])


class ShellWiringTests(unittest.TestCase):
    def test_service_runs_the_script_through_uv(self):
        source = (ROOT / "Services/UI/WallpaperCutoutService.qml").read_text()
        self.assertIn("Scripts/python/src/wallpaper/wallpaper-cutout.py", source)
        self.assertIn("rembg[cpu]", source)

    def test_helper_translation_keys_exist(self):
        # The helper names keys the QML translation check cannot see
        english = json.loads((ROOT / "Assets/Translations/en.json").read_text())
        helper = (ROOT / "Helpers/WallpaperVisualizer.js").read_text()
        keys = re.findall(r'"(panels\.[a-z.-]+)"', helper)
        self.assertGreater(len(keys), 5)
        for key in keys:
            node = english
            for part in key.split("."):
                node = node.get(part, {}) if isinstance(node, dict) else {}
            with self.subTest(key=key):
                self.assertIsInstance(node, str)

    def test_visualizer_is_loaded_by_the_shell(self):
        shell = (ROOT / "shell.qml").read_text()
        self.assertIn("WallpaperVisualizer {}", shell)


if __name__ == "__main__":
    unittest.main()
