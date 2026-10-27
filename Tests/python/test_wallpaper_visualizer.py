"""Wallpaper visualizer look settings: the JS fallbacks, the shader uniforms and the hint strings stay in step."""
import json
import pathlib
import re
import unittest

import settings_defaults

ROOT = pathlib.Path(__file__).resolve().parents[2]
HELPER = (ROOT / "Helpers/WallpaperVisualizer.js").read_text(encoding="utf-8")
SHADER = (ROOT / "Shaders/frag/edge_wave.frag").read_text(encoding="utf-8")
WAVES = (ROOT / "Modules/WallpaperVisualizer/EdgeWaves.qml").read_text(encoding="utf-8")
LOOK_KEYS = ["whiteness", "rim", "backWave", "softness"]


class LookTests(unittest.TestCase):
    def test_look_fallbacks_match_settings_defaults(self):
        fallbacks = dict(re.findall(r'"(\w+)": clamp\(prefs\.\w+, \w+Range, ([\d.]+)\)', HELPER))
        self.assertEqual(sorted(fallbacks), sorted(LOOK_KEYS))
        for key in LOOK_KEYS:
            self.assertEqual(float(fallbacks[key]), settings_defaults.lookup("wallpaperVisualizer." + key), key)

    def test_look_settings_are_shader_uniforms(self):
        block = SHADER[SHADER.index("uniform buf {"):SHADER.index("};")]
        for key in LOOK_KEYS:
            self.assertRegex(block, r"float %s;" % key)
            self.assertIn("property real %s: root.look.%s" % (key, key), WAVES)

    def test_hint_keys_are_translated(self):
        strings = json.loads((ROOT / "Assets/Translations/en.json").read_text(encoding="utf-8"))
        keys = re.findall(r'"\w+": "(panels\.desktop-widgets\.effect-hint-[\w-]+)"', HELPER)
        self.assertEqual(len(keys), 3)
        for key in keys:
            node = strings
            for part in key.split("."):
                node = node[part]
            self.assertIsInstance(node, str, key)


if __name__ == "__main__":
    unittest.main()
