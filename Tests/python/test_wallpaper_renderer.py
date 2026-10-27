"""The shell's own wallpaper renderer: its shaders, settings, IPC and wiring."""
import pathlib
import re
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
HELPER = (ROOT / "Helpers/WallpaperRenderer.js").read_text()


def read(path):
    return (ROOT / path).read_text()


class ShaderTests(unittest.TestCase):
    def test_every_style_has_compiled_shader(self):
        shaders = re.findall(r'"shader":\s*"(\w+)"', HELPER)
        self.assertGreaterEqual(len(shaders), 11)
        for shader in shaders:
            with self.subTest(shader=shader):
                self.assertTrue((ROOT / f"Shaders/frag/{shader}.frag").exists())
                self.assertTrue((ROOT / f"Shaders/qsb/{shader}.frag.qsb").exists())

    def test_sekai_shaders_are_credited(self):
        for path in (ROOT / "Shaders/frag").glob("wp_sekai_*.frag"):
            with self.subTest(shader=path.name):
                source = path.read_text()
                self.assertIn("github.com/Blapples/SekaiPop, GPL-3.0", source)
                # Ported to run with Qt's default vertex shader, no .vert pair
                self.assertNotIn(".vert", source)
        self.assertIn("SekaiPop", read("CREDITS.md"))

    def test_transition_options_are_styles(self):
        tab = read("Modules/Panels/Settings/Tabs/Wallpaper/TransitionsSubTab.qml")
        options = set(re.findall(r'"key":\s*"(\w+)"', tab.split("ring-variant-label")[0]))
        styles = set(re.findall(r'^  "(\w+)": \{\s*\n\s*"shader"', HELPER, re.MULTILINE))
        self.assertEqual(options, styles | {"random", "none"})


class WiringTests(unittest.TestCase):
    def test_off_by_default(self):
        settings = read("Commons/Settings.qml")
        block = settings[settings.index("property JsonObject wallpaperRenderer"):]
        self.assertIn("property bool enabled: false", block[:block.index("}")])

    def test_layer_is_on_the_background_under_the_visualizer(self):
        layer = read("Modules/Background/WallpaperLayer.qml")
        self.assertIn("WlrLayer.Background", layer)
        self.assertIn("mask: Region {}", layer)
        shell = read("shell.qml")
        self.assertLess(shell.index("ShellWallpaper {}"), shell.index("WallpaperVisualizer {}"))
        self.assertIn("WallpaperService.rendererEnabled", read("Modules/Background/ShellWallpaper.qml"))

    def test_waves_are_drawn_inside_the_wallpaper_window(self):
        # Regression: the waves had their own window on the background layer, which
        # stacks by map order, and the wallpaper's window mapped over them
        layer = read("Modules/Background/WallpaperLayer.qml")
        stage = layer[layer.index("id: stage"):]
        self.assertIn("ScreenWaves {", stage[stage.index("id: picture"):])
        visualizer = read("Modules/WallpaperVisualizer/WallpaperVisualizer.qml")
        self.assertIn("!WallpaperService.rendererEnabled", visualizer)
        self.assertIn("ScreenWaves {", visualizer)
        self.assertNotIn("restack", visualizer)

    def test_getwallpaper_api_kept(self):
        service = read("Services/UI/WallpaperService.qml")
        for name in ("getWallpaper", "getWallpapersEffectiveMap", "refresh", "setWallpaper", "next", "previous", "random", "setMode"):
            self.assertRegex(service, rf"function {name}\(")
        self.assertIn("signal wallpaperChanged(string screenName, string path)", service)
        self.assertIn("ImageCacheService.getScreenWallpaper", service)

    def test_ipc(self):
        ipc = read("Services/Control/IPCService.qml")
        body = ipc[ipc.index('target: "wallpaper"'):]
        body = body[:body.index("IpcHandler {")]
        for name in ("set", "setFor", "next", "previous", "random", "mode", "light", "dark", "auto", "get", "getMode", "clearCache"):
            self.assertRegex(body, rf"function {name}\(")

    def test_settings_tab_registered(self):
        self.assertIn("Wallpaper", re.search(r"enum Tab \{([^}]+)\}", read("Modules/Panels/Settings/SettingsPanel.qml")).group(1))
        self.assertIn('"id": SettingsPanel.Tab.Wallpaper', read("Modules/Panels/Settings/SettingsContent.qml"))
        self.assertIn('"wallpaper": SettingsPanel.Tab.Wallpaper', read("Services/Control/IPCService.qml"))

    def test_mode_switch_reads_the_new_modes_folder(self):
        # Regression: onModeChanged ran before `images` and `listed` followed the new mode,
        # so `wallpaper dark` showed a random light picture and remembered it as dark
        service = read("Services/UI/WallpaperService.qml")
        fn = service[service.index("function pickForMode"):]
        fn = re.sub(r'"[^"]*"', '""', fn[:fn.index("\n  }\n")])
        self.assertNotRegex(fn, r"\bimages\b")
        self.assertNotRegex(fn, r"(?<![A-Za-z])listed\b")
        self.assertIn("darkImages", fn)
        self.assertIn("lightImages", fn)

    def test_parallax_zooms_the_picture_and_the_cache(self):
        layer = read("Modules/Background/WallpaperLayer.qml")
        self.assertIn("clip: win.zoom > 1", layer)
        self.assertIn("width: stage.width * win.zoom", layer)
        self.assertIn("WallpaperRenderer.parallaxShift(win.slide", layer)
        self.assertIn("CompositorService", layer)
        service = read("Services/UI/WallpaperService.qml")
        # The copies on screen and the precached ones are cut at the same zoomed size
        self.assertEqual(service.count("cacheSize("), service.count("devicePixelRatio, zoom)"))
        self.assertIn("onZoomChanged", service)
        settings = read("Commons/Settings.qml")
        block = settings[settings.index("property JsonObject wallpaperRenderer"):]
        self.assertIn("property bool parallax: false", block[:block.index("}")])

    def test_screen_cache_written_atomically(self):
        cache = read("Services/UI/ImageCacheService.qml")
        fn = cache[cache.index("function startScreenWallpaperProcessing"):]
        fn = fn[:fn.index("\n  }\n")]
        self.assertIn(".tmp.jpg", fn)
        self.assertIn("mv -f", fn)
        self.assertIn("-extent", fn)


if __name__ == "__main__":
    unittest.main()
