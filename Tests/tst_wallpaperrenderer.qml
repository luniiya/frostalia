import QtQuick
import QtTest
import "../Helpers/WallpaperRenderer.js" as WallpaperRenderer

TestCase {
  name: "WallpaperRenderer"

  readonly property var prefs: ({
                                  "lightFolder": "~/Wall/Light/",
                                  "darkFolder": "/srv/walls/Dark"
                                })

  // A fixed sequence instead of Math.random
  function seq(values) {
    let i = 0;
    return () => values[i++ % values.length];
  }

  function test_expandHome_data() {
    return [
          {
            tag: "tilde path",
            p: "~/Wall/Light",
            e: "/home/u/Wall/Light"
          },
          {
            tag: "tilde alone",
            p: "~",
            e: "/home/u"
          },
          {
            tag: "absolute",
            p: " /srv/w ",
            e: "/srv/w"
          },
          {
            tag: "tilde inside",
            p: "/a/~/b",
            e: "/a/~/b"
          },
          {
            tag: "empty",
            p: undefined,
            e: ""
          }
        ];
  }

  function test_expandHome(data) {
    compare(WallpaperRenderer.expandHome(data.p, "/home/u"), data.e);
  }

  function test_normalizeFolder() {
    compare(WallpaperRenderer.normalizeFolder("~/Wall/Light///", "/home/u"), "/home/u/Wall/Light");
    compare(WallpaperRenderer.normalizeFolder("/", "/home/u"), "/");
  }

  function test_isImage_data() {
    return [
          {
            tag: "png",
            n: "/w/a b.png",
            e: true
          },
          {
            tag: "upper case",
            n: "/w/A.JPG",
            e: true
          },
          {
            tag: "webp",
            n: "x.webp",
            e: true
          },
          {
            tag: "text",
            n: "/w/README.md",
            e: false
          },
          {
            tag: "script",
            n: "/w/jpg_to_png.sh",
            e: false
          },
          {
            tag: "hidden file without extension",
            n: "/w/.png",
            e: false
          },
          {
            tag: "no extension",
            n: "/w/png",
            e: false
          }
        ];
  }

  function test_isImage(data) {
    compare(WallpaperRenderer.isImage(data.n), data.e);
  }

  function test_sortedImages_filtersAndSortsNaturally() {
    compare(WallpaperRenderer.sortedImages(["/w/b10.png", "/w/notes.txt", "/w/B2.jpg", "/w/a.png"]), ["/w/a.png", "/w/B2.jpg", "/w/b10.png"]);
    compare(WallpaperRenderer.sortedImages(null), []);
  }

  function test_modeFor_data() {
    return [
          {
            tag: "follows dark",
            dark: true,
            o: "",
            e: "dark"
          },
          {
            tag: "follows light",
            dark: false,
            o: "",
            e: "light"
          },
          {
            tag: "override light",
            dark: true,
            o: "light",
            e: "light"
          },
          {
            tag: "override dark",
            dark: false,
            o: "dark",
            e: "dark"
          },
          {
            tag: "bad override ignored",
            dark: false,
            o: "sepia",
            e: "light"
          }
        ];
  }

  function test_modeFor(data) {
    compare(WallpaperRenderer.modeFor(data.dark, data.o), data.e);
  }

  function test_normalizeMode_data() {
    return [
          {
            tag: "light",
            a: "Light",
            e: "light"
          },
          {
            tag: "dark",
            a: " DARK ",
            e: "dark"
          },
          {
            tag: "auto",
            a: "auto",
            e: "auto"
          },
          {
            tag: "follow",
            a: "follow",
            e: "auto"
          },
          {
            tag: "unknown",
            a: "dusk",
            e: ""
          },
          {
            tag: "empty",
            a: "",
            e: ""
          }
        ];
  }

  function test_normalizeMode(data) {
    compare(WallpaperRenderer.normalizeMode(data.a), data.e);
  }

  function test_folders() {
    compare(WallpaperRenderer.folderFor("light", prefs, "/home/u"), "/home/u/Wall/Light");
    compare(WallpaperRenderer.folderFor("dark", prefs, "/home/u"), "/srv/walls/Dark");
    compare(WallpaperRenderer.folderFor("dark", null, "/home/u"), "");
  }

  function test_modeOfPath() {
    compare(WallpaperRenderer.modeOfPath("/home/u/Wall/Light/a.png", prefs, "/home/u"), "light");
    compare(WallpaperRenderer.modeOfPath("/srv/walls/Dark/sub/b.png", prefs, "/home/u"), "dark");
    // Not fooled by a folder whose name starts the same
    compare(WallpaperRenderer.modeOfPath("/srv/walls/Darker/c.png", prefs, "/home/u"), "");
    compare(WallpaperRenderer.modeOfPath("/tmp/d.png", prefs, "/home/u"), "");
  }

  function test_modeForPicture() {
    // The mode asked wins, even for a picture in the other mode's folder
    compare(WallpaperRenderer.modeForPicture("/home/u/Wall/Light/a.png", "dark", prefs, "/home/u", "light"), "dark");
    compare(WallpaperRenderer.modeForPicture("/tmp/d.png", "Light", prefs, "/home/u", "dark"), "light");
    // Otherwise the folder's, else the current one
    compare(WallpaperRenderer.modeForPicture("/srv/walls/Dark/b.png", "", prefs, "/home/u", "light"), "dark");
    compare(WallpaperRenderer.modeForPicture("/tmp/d.png", undefined, prefs, "/home/u", "light"), "light");
    compare(WallpaperRenderer.modeForPicture("/tmp/d.png", "auto", prefs, "/home/u", "dark"), "dark");
  }

  function test_pickRandom() {
    const list = ["a", "b", "c"];
    compare(WallpaperRenderer.pickRandom(list, ["a"], seq([0])), "b");
    compare(WallpaperRenderer.pickRandom(list, ["a"], seq([0.99])), "c");
    // Everything avoided: anything but the first avoided one
    compare(WallpaperRenderer.pickRandom(list, ["a", "b", "c"], seq([0])), "b");
    // A single picture that is already shown is still the only choice
    compare(WallpaperRenderer.pickRandom(["a"], ["a"], seq([0])), "");
    compare(WallpaperRenderer.pickRandom([], [], seq([0])), "");
    // rand() returning 1 doesn't run off the end
    compare(WallpaperRenderer.pickRandom(list, [], seq([1])), "c");
  }

  function test_step_data() {
    return [
          {
            tag: "next",
            cur: "b",
            d: 1,
            e: "c"
          },
          {
            tag: "next wraps",
            cur: "c",
            d: 1,
            e: "a"
          },
          {
            tag: "previous wraps",
            cur: "a",
            d: -1,
            e: "c"
          },
          {
            tag: "unknown next",
            cur: "z",
            d: 1,
            e: "a"
          },
          {
            tag: "unknown previous",
            cur: "",
            d: -1,
            e: "c"
          }
        ];
  }

  function test_step(data) {
    compare(WallpaperRenderer.step(["a", "b", "c"], data.cur, data.d), data.e);
  }

  function test_step_emptyList() {
    compare(WallpaperRenderer.step([], "a", 1), "");
  }

  function test_startingPicture() {
    compare(WallpaperRenderer.startingPicture(["a", "b"], "b", seq([0])), "b");
    // Remembered picture gone from the folder: a random one
    compare(WallpaperRenderer.startingPicture(["a", "b"], "gone", seq([0.6])), "b");
    compare(WallpaperRenderer.startingPicture([], "b", seq([0])), "");
    // Regression: lumen shows a picture from outside the folder for dark, then switches
    // to dark; the picture on screen stays instead of a second, random change
    compare(WallpaperRenderer.startingPicture(["/d/a", "/d/b"], "/season/medusa.png", seq([0]), "/season/medusa.png"), "/season/medusa.png");
    // Not on screen and not in the folder: still a random one
    compare(WallpaperRenderer.startingPicture(["/d/a", "/d/b"], "/season/medusa.png", seq([0]), "/l/x"), "/d/a");
  }

  function test_styleForSwitch() {
    compare(WallpaperRenderer.styleForSwitch("star", "ring"), "star");
    compare(WallpaperRenderer.styleForSwitch("none", ""), "none");
    compare(WallpaperRenderer.styleForSwitch("bogus", ""), "ring");
    compare(WallpaperRenderer.styleForSwitch("random", "", seq([0])), WallpaperRenderer.randomPool[0]);
    // Random never plays the same style twice in a row
    let last = "ring";
    const rand = seq([0, 0.3, 0.5, 0.99, 0.1]);
    for (let i = 0; i < 20; i++) {
      const next = WallpaperRenderer.styleForSwitch("random", last, rand);
      verify(next !== last, "repeated " + next);
      verify(WallpaperRenderer.randomPool.indexOf(next) >= 0);
      last = next;
    }
  }

  function test_everyStyleHasAShader() {
    const names = Object.keys(WallpaperRenderer.styles);
    for (const style of names) {
      verify(WallpaperRenderer.shaderFor(style).indexOf("wp_") === 0, style);
      verify(["sekai", "classic"].indexOf(WallpaperRenderer.familyFor(style)) >= 0, style);
    }
    for (const style of WallpaperRenderer.randomPool)
      verify(names.indexOf(style) >= 0, style);
    verify(WallpaperRenderer.randomPool.indexOf("fade") < 0);
    compare(WallpaperRenderer.shaderFor("none"), "");
  }

  function test_timing() {
    compare(WallpaperRenderer.durationFor("ring", 1300), 1300);
    compare(WallpaperRenderer.durationFor("iris", 1300), 2000);
    compare(WallpaperRenderer.durationFor("none", 1300), 0);
    compare(WallpaperRenderer.durationFor("fade", -5), 0);
    verify(WallpaperRenderer.linearFor("ring"));
    verify(WallpaperRenderer.linearFor("blocks"));
    verify(!WallpaperRenderer.linearFor("flash"));
    verify(!WallpaperRenderer.linearFor("wipe"));
  }

  function test_ringVariantIndex() {
    compare(WallpaperRenderer.ringVariantIndex("ring"), 0);
    compare(WallpaperRenderer.ringVariantIndex("swirl"), 3);
    compare(WallpaperRenderer.ringVariantIndex("??"), 0);
  }

  function test_classicParams() {
    const p = WallpaperRenderer.classicParams(seq([0.99, 0.25, 0.75, 0.5]));
    compare(p.direction, 3);
    compare(p.centerX, 0.25);
    compare(p.centerY, 0.75);
    compare(p.angle, 180);
  }

  function test_cacheSize() {
    compare(WallpaperRenderer.cacheSize(2256, 1504, 1), {
              "width": 2256,
              "height": 1504
            });
    compare(WallpaperRenderer.cacheSize(1280, 720, 1.5), {
              "width": 1920,
              "height": 1080
            });
    compare(WallpaperRenderer.cacheSize(0, 0, 0), {
              "width": 1,
              "height": 1
            });
    // Parallax zoom makes the cached copy larger than the screen
    compare(WallpaperRenderer.cacheSize(1920, 1080, 1, 1.1), {
              "width": 2112,
              "height": 1188
            });
    compare(WallpaperRenderer.cacheSize(1920, 1080, 1, 0.5), {
              "width": 1920,
              "height": 1080
            });
  }

  function test_parallaxZoom() {
    compare(WallpaperRenderer.parallaxZoom(false, 10), 1);
    compare(WallpaperRenderer.parallaxZoom(true, 10), 1.1);
    compare(WallpaperRenderer.parallaxZoom(true, -5), 1);
    compare(WallpaperRenderer.parallaxZoom(true, 500), 1.5);
    compare(WallpaperRenderer.parallaxZoom(true, "x"), 1);
  }

  function test_activeWorkspace() {
    const ws = [
            {
              "idx": 1,
              "output": "DP-1",
              "isActive": false,
              "isFocused": false
            },
            {
              "idx": 3,
              "output": "DP-1",
              "isActive": true,
              "isFocused": false
            },
            {
              "idx": 6,
              "output": "eDP-1",
              "isActive": true,
              "isFocused": true
            }
          ];
    compare(WallpaperRenderer.activeWorkspace(ws, "DP-1"), 3);
    compare(WallpaperRenderer.activeWorkspace(ws, "eDP-1"), 6);
    compare(WallpaperRenderer.activeWorkspace(ws, "HDMI-A-1"), 0);
    // No per-output workspaces: the focused one counts for every screen
    compare(WallpaperRenderer.activeWorkspace([
                                                {
                                                  "idx": 2,
                                                  "output": "",
                                                  "isActive": true,
                                                  "isFocused": true
                                                }
                                              ], "DP-1"), 2);
    compare(WallpaperRenderer.activeWorkspace([], "DP-1"), 0);
    compare(WallpaperRenderer.activeWorkspace(null, "DP-1"), 0);
  }

  function test_parallaxFraction_data() {
    return [
          {
            "tag": "first",
            "idx": 1,
            "count": 5,
            "expected": 0
          },
          {
            "tag": "last",
            "idx": 5,
            "count": 5,
            "expected": 1
          },
          {
            "tag": "middle",
            "idx": 3,
            "count": 5,
            "expected": 0.5
          },
          {
            "tag": "past the end",
            "idx": 9,
            "count": 5,
            "expected": 1
          },
          {
            "tag": "unknown workspace",
            "idx": 0,
            "count": 5,
            "expected": 0.5
          },
          {
            "tag": "one workspace",
            "idx": 1,
            "count": 1,
            "expected": 0.5
          }
        ];
  }

  function test_parallaxFraction(data) {
    compare(WallpaperRenderer.parallaxFraction(data.idx, data.count), data.expected);
  }

  function test_parallaxShift() {
    compare(WallpaperRenderer.parallaxShift(0, 1920, 1.1), -0);
    fuzzyCompare(WallpaperRenderer.parallaxShift(1, 1920, 1.1), -192, 0.001);
    fuzzyCompare(WallpaperRenderer.parallaxShift(0.5, 1080, 1.1), -54, 0.001);
    compare(WallpaperRenderer.parallaxShift(1, 1920, 1), -0);
    // Clamped to the spare width
    fuzzyCompare(WallpaperRenderer.parallaxShift(3, 1920, 1.1), -192, 0.001);
  }

  function test_precacheOrder() {
    const list = ["a", "b", "c", "d"];
    // Upcoming first, then the folder from the current picture on, current skipped
    compare(WallpaperRenderer.precacheOrder(list, "b", ["d", "c", "zz", ""]), ["d", "c", "a"]);
    compare(WallpaperRenderer.precacheOrder(list, "", []), ["a", "b", "c", "d"]);
    compare(WallpaperRenderer.precacheOrder([], "a", ["a"]), []);
  }

  function test_mixHex() {
    compare(WallpaperRenderer.mixHex("#000000", "#ffffff", 0.5), "#808080");
    compare(WallpaperRenderer.mixHex("#ff0000", "#0000ff", 0), "#ff0000");
    compare(WallpaperRenderer.mixHex("nope", "#ffffff", 0.5), "nope");
  }

  function test_transitionColors_sekai() {
    compare(WallpaperRenderer.transitionColors("sekai", "#123456", "#654321", "#abcdef"), WallpaperRenderer.sekaiColors);
    // A broken palette falls back to SekaiPop's colours
    compare(WallpaperRenderer.transitionColors("theme", "", "", ""), WallpaperRenderer.sekaiColors);
  }

  function test_transitionColors_theme() {
    const c = WallpaperRenderer.transitionColors("theme", "#37f499", "#04d1f9", "#a48cf2");
    compare(c.cyan, "#37f499");
    compare(c.pink, "#04d1f9");
    compare(c.green, "#a48cf2");
    compare(c.white, WallpaperRenderer.mixHex("#ffffff", "#37f499", 0.1));
    // Qt's #AARRGGBB form is read too
    compare(WallpaperRenderer.transitionColors("theme", "#ff37f499", "#ff04d1f9", "").green, "#37f499");
  }

  function test_transitionColors_monochromeGetsLighterPink() {
    const c = WallpaperRenderer.transitionColors("theme", "#808080", "#858585", "#808080");
    compare(c.pink, WallpaperRenderer.mixHex("#858585", "#ffffff", 0.45));
    verify(WallpaperRenderer.colorDistance(c.pink, c.cyan) >= 0.12);
  }

  function test_intervalMs() {
    // Off whatever the minutes say
    compare(WallpaperRenderer.intervalMs(false, 15), 0);
    compare(WallpaperRenderer.intervalMs(true, 15), 900000);
    // On is never "never": a broken or zero value is a minute
    compare(WallpaperRenderer.intervalMs(true, 0), 60000);
    compare(WallpaperRenderer.intervalMs(true, -3), 60000);
    compare(WallpaperRenderer.intervalMs(true, "x"), 60000);
  }

  function test_cacheAllOrder() {
    compare(WallpaperRenderer.cacheAllOrder(["/l/a", "/l/b"], ["/d/c", "/l/a", ""]), ["/l/a", "/l/b", "/d/c"]);
    compare(WallpaperRenderer.cacheAllOrder(null, ["/d/c"]), ["/d/c"]);
    compare(WallpaperRenderer.cacheAllOrder([], []), []);
  }

  function test_changeHook_none_without_command_or_path() {
    compare(WallpaperRenderer.changeHook("", "/w/a.png", "dark"), null);
    compare(WallpaperRenderer.changeHook("   ", "/w/a.png", "dark"), null);
    compare(WallpaperRenderer.changeHook("wallust run \"$WALLPAPER\"", "", "dark"), null);
  }

  function test_changeHook_passes_path_and_mode_in_the_environment() {
    const hook = WallpaperRenderer.changeHook("wallust run \"$WALLPAPER\"", "/w/it's a.png", "light");
    compare(hook.command, ["sh", "-c", "wallust run \"$WALLPAPER\""]);
    compare(hook.environment.WALLPAPER, "/w/it's a.png");
    compare(hook.environment.WALLPAPER_MODE, "light");
  }

  function test_changeHook_mode_defaults_to_dark() {
    compare(WallpaperRenderer.changeHook("true", "/w/a.png", "").environment.WALLPAPER_MODE, "dark");
    compare(WallpaperRenderer.changeHook("true", "/w/a.png", "dark").environment.WALLPAPER_MODE, "dark");
  }

  function test_publishCommand_empty() {
    compare(WallpaperRenderer.publishCommand("", "/c/wallpaper"), "");
    compare(WallpaperRenderer.publishCommand("/w/a.png", ""), "");
  }

  function test_publishCommand() {
    const cmd = WallpaperRenderer.publishCommand("/w/it's a.gif", "/c/wallpaper/");
    verify(cmd.startsWith("mkdir -p '/c/wallpaper' && "));
    // The link keeps the original, quoted, and is swapped in whole
    verify(cmd.indexOf("ln -sfn '/w/it'\\''s a.gif' '/c/wallpaper/current.tmp' && mv -Tf '/c/wallpaper/current.tmp' '/c/wallpaper/current'") >= 0);
    // The PNG is the first frame, written beside the published file and moved over it
    // A GIF's first frame comes from ffmpeg (Helpers/StillFrame.js)
    verify(cmd.indexOf("ffmpeg -v error -nostdin -threads 1 -i '/w/it'\\''s a.gif' -frames:v 1") >= 0);
    verify(cmd.indexOf("magick png:- -auto-orient '/c/wallpaper/current.tmp.png' && mv -f '/c/wallpaper/current.tmp.png' '/c/wallpaper/current.png'") >= 0);
    // Anything else is read by magick, under its memory caps
    verify(WallpaperRenderer.publishCommand("/w/a.png", "/c").indexOf("MAGICK_MEMORY_LIMIT=1GiB MAGICK_MAP_LIMIT=2GiB MAGICK_DISK_LIMIT=1GiB magick '/w/a.png[0]' -auto-orient") >= 0);
  }
}
