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


class WaveSettingsTests(unittest.TestCase):
    def test_wave_settings_are_not_drawn_inside_the_shelf(self):
        # The popover sits above the shelf; keycap renders the shelf into a layer for its
        # shadow, which clipped the popover down to a strip under the card
        shelf = (ROOT / "Modules/EditDesktop/EditShelf.qml").read_text()
        popover = shelf[shelf.index("id: waveSettings"):]
        popover = popover[:popover.index("NStyleCard")]
        self.assertIn("parent: root.parent", popover)
        self.assertIn("root.y - height", popover)

    def test_effect_tiles_are_opaque(self):
        # A translucent fill let keycap's shifted shadow copy show through: doubled icon and label
        shelf = (ROOT / "Modules/EditDesktop/EditShelf.qml").read_text()
        tile = shelf[shelf.index("component EffectTile"):]
        fill = next(line for line in tile.splitlines() if line.strip().startswith("color: effect.lit"))
        self.assertNotRegex(fill, r"[?:]\s*Qt\.alpha\(")

    def test_edges_are_combined_without_merging(self):
        # Merging neighbouring edges' waves (a smooth union) filled in blobs and holes
        # ("cheese") far from the edges; the loop makes corners meet at one height instead
        shader = (ROOT / "Shaders/frag/edge_wave.frag").read_text()
        self.assertNotIn("smoothUnion", shader)
        # One shape: the nearest crest of any edge, so crossing waves don't show each other's rim
        self.assertIn("if (wave.x < front) {", shader)

    def test_loop_uniforms_are_set(self):
        waves = (ROOT / "Modules/WallpaperVisualizer/EdgeWaves.qml").read_text()
        for name in ("lobes", "drift", "frame"):
            self.assertRegex(waves, r"property real %s:" % name)

    def test_nothing_is_drawn_past_the_rim(self):
        # The body's glow and the back wave stuck out past the white crest line
        shader = (ROOT / "Shaders/frag/edge_wave.frag").read_text()
        self.assertIn("smoothstep(-glow, 0.0, front)", shader)
        self.assertIn("back *= inside;", shader)
