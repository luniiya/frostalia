import QtQuick
import QtTest
import "../Helpers/WallpaperVisualizer.js" as WallpaperVisualizer

TestCase {
  name: "WallpaperVisualizer"

  function test_edgeFlags_data() {
    return [
          {
            tag: "all",
            edges: "all",
            e: [1, 1, 1, 1]
          },
          {
            tag: "top and bottom",
            edges: "topBottom",
            e: [1, 1, 0, 0]
          },
          {
            tag: "left and right",
            edges: "leftRight",
            e: [0, 0, 1, 1]
          },
          {
            tag: "top",
            edges: "top",
            e: [1, 0, 0, 0]
          },
          {
            tag: "left",
            edges: "left",
            e: [0, 0, 1, 0]
          },
          {
            tag: "right",
            edges: "right",
            e: [0, 0, 0, 1]
          },
          {
            tag: "bottom",
            edges: "bottom",
            e: [0, 1, 0, 0]
          },
          {
            tag: "unknown falls back to all",
            edges: "sideways",
            e: [1, 1, 1, 1]
          }
        ];
  }

  function test_edgeFlags(data) {
    compare(WallpaperVisualizer.edgeFlags(data.edges), data.e);
  }

  function test_every_edge_choice_has_flags() {
    for (const choice of WallpaperVisualizer.edgeChoices)
      verify(WallpaperVisualizer.edgeFlags(choice).indexOf(1) >= 0, choice);
  }

  function test_clamp() {
    compare(WallpaperVisualizer.clamp(2, WallpaperVisualizer.heightRange, 0.2), 0.5);
    compare(WallpaperVisualizer.clamp(0, WallpaperVisualizer.heightRange, 0.2), 0.05);
    compare(WallpaperVisualizer.clamp("x", WallpaperVisualizer.heightRange, 0.2), 0.2);
    compare(WallpaperVisualizer.clamp(0.3, WallpaperVisualizer.heightRange, 0.2), 0.3);
  }

  function test_isAnimated() {
    verify(WallpaperVisualizer.isAnimated("/w/blue city.gif"));
    verify(WallpaperVisualizer.isAnimated("/w/LOOP.GIF"));
    verify(!WallpaperVisualizer.isAnimated("/w/still.png"));
    verify(!WallpaperVisualizer.isAnimated(""));
  }

  function test_parseResult() {
    const line = '{"source": "/w/a.png", "separable": true, "model": "isnet-anime", "image": "/c/k.png", "coverage": 0.2}';
    compare(WallpaperVisualizer.parseResult("Downloading model...\n" + line + "\n").image, "/c/k.png");
    compare(WallpaperVisualizer.parseResult(""), null);
    compare(WallpaperVisualizer.parseResult("Traceback (most recent call last):\n  oops"), null);
    compare(WallpaperVisualizer.parseResult('{"other": 1}'), null);
  }

  function test_cutoutFor() {
    const results = {
      "/w/a.png": {
        "source": "/w/a.png",
        "separable": true,
        "image": "/c/a.png"
      },
      "/w/b.png": {
        "source": "/w/b.png",
        "separable": false,
        "image": ""
      }
    };
    compare(WallpaperVisualizer.cutoutFor(results, "/w/a.png"), "/c/a.png");
    compare(WallpaperVisualizer.cutoutFor(results, "/w/b.png"), "");
    compare(WallpaperVisualizer.cutoutFor(results, "/w/c.png"), "");
    compare(WallpaperVisualizer.cutoutFor(results, ""), "");
    compare(WallpaperVisualizer.cutoutFor(null, "/w/a.png"), "");
  }

  function test_nextRequest() {
    const results = {
      "/w/done.png": {
        "source": "/w/done.png"
      }
    };
    compare(WallpaperVisualizer.nextRequest(["/w/old.png", "/w/new.png"], results), "/w/new.png");
    compare(WallpaperVisualizer.nextRequest(["/w/old.png", "/w/done.png"], results), "/w/old.png");
    compare(WallpaperVisualizer.nextRequest(["/w/loop.gif", "/w/done.png"], results), "");
    compare(WallpaperVisualizer.nextRequest([], results), "");
  }

  function test_wavesActive() {
    verify(WallpaperVisualizer.wavesActive(true, false, false));
    verify(!WallpaperVisualizer.wavesActive(false, false, false));
    verify(!WallpaperVisualizer.wavesActive(true, true, false));
    verify(!WallpaperVisualizer.wavesActive(true, false, true));
  }

  function test_nextEdges() {
    compare(WallpaperVisualizer.nextEdges("all"), "topBottom");
    compare(WallpaperVisualizer.nextEdges("topBottom"), "leftRight");
    compare(WallpaperVisualizer.nextEdges("leftRight"), "top");
    compare(WallpaperVisualizer.nextEdges("top"), "bottom");
    compare(WallpaperVisualizer.nextEdges("bottom"), "left");
    compare(WallpaperVisualizer.nextEdges("left"), "right");
    compare(WallpaperVisualizer.nextEdges("right"), "all");
    compare(WallpaperVisualizer.nextEdges("unknown"), "all");
  }

  function test_depthStatus() {
    const results = {
      "/w/a.png": {
        "source": "/w/a.png",
        "separable": true,
        "image": "/c/a.png"
      },
      "/w/b.png": {
        "source": "/w/b.png",
        "separable": false,
        "image": ""
      }
    };
    compare(WallpaperVisualizer.depthStatus(results, "/w/a.png", false), "off");
    compare(WallpaperVisualizer.depthStatus(results, "/w/a.png", true), "found");
    compare(WallpaperVisualizer.depthStatus(results, "/w/b.png", true), "none");
    compare(WallpaperVisualizer.depthStatus(results, "/w/c.png", true), "pending");
    compare(WallpaperVisualizer.depthStatus(results, "/w/loop.gif", true), "animated");
  }

  function test_label_keys() {
    compare(WallpaperVisualizer.edgeLabelKey("topBottom"), "panels.audio.wallpaper-visualizer-edges-top-bottom");
    compare(WallpaperVisualizer.edgeLabelKey("nope"), "panels.audio.wallpaper-visualizer-edges-all");
    for (const choice of WallpaperVisualizer.edgeChoices)
      verify(WallpaperVisualizer.edgeLabelKeys[choice] !== undefined, choice);
    for (const status of ["off", "animated", "pending", "found", "none"])
      verify(WallpaperVisualizer.depthLabelKey(status).indexOf("panels.desktop-widgets.effect-") === 0, status);
    compare(WallpaperVisualizer.depthLabelKey("weird"), "panels.desktop-widgets.effect-off");
  }

  function test_look_defaults() {
    compare(WallpaperVisualizer.look({}), {
              "whiteness": 0.65,
              "rim": 0.85,
              "backWave": 0.35,
              "softness": 0.08
            });
    compare(WallpaperVisualizer.look(null).rim, 0.85);
  }

  function test_look_clamps() {
    const look = WallpaperVisualizer.look({
                                            "whiteness": 2,
                                            "rim": -1,
                                            "backWave": "x",
                                            "softness": 0
                                          });
    compare(look.whiteness, 1);
    compare(look.rim, 0);
    compare(look.backWave, 0.35);
    compare(look.softness, WallpaperVisualizer.softnessRange[0]);
  }

  function test_look_ranges_hold_their_defaults() {
    const look = WallpaperVisualizer.look({});
    const ranges = {
      "whiteness": WallpaperVisualizer.whitenessRange,
      "rim": WallpaperVisualizer.rimRange,
      "backWave": WallpaperVisualizer.backWaveRange,
      "softness": WallpaperVisualizer.softnessRange
    };
    for (const key in ranges)
      verify(look[key] >= ranges[key][0] && look[key] <= ranges[key][1], key);
  }

  function test_demoSpectrum_shape() {
    for (const t of [0, 0.37, 1.9, 42]) {
      const values = WallpaperVisualizer.demoSpectrum(32, t);
      compare(values.length, 32);
      for (const v of values)
        verify(isFinite(v) && v >= 0 && v <= 1, "t=" + t + " v=" + v);
    }
    compare(WallpaperVisualizer.demoSpectrum(0, 1), []);
    compare(WallpaperVisualizer.demoSpectrum(1, 1).length, 1);
  }

  function test_demoSpectrum_moves() {
    const a = WallpaperVisualizer.demoSpectrum(32, 0);
    const b = WallpaperVisualizer.demoSpectrum(32, 0.25);
    verify(a.some((v, i) => Math.abs(v - b[i]) > 0.01));
    compare(WallpaperVisualizer.demoSpectrum(32, 0.25), b);
  }

  function test_demoSpectrum_louder_in_the_lows() {
    let lows = 0;
    let highs = 0;
    for (let t = 0; t < 4; t += 0.1) {
      const values = WallpaperVisualizer.demoSpectrum(32, t);
      lows += values[0] + values[1] + values[2];
      highs += values[29] + values[30] + values[31];
    }
    verify(lows > highs);
  }

  function test_previewEffect() {
    compare(WallpaperVisualizer.previewEffect("", false), "");
    compare(WallpaperVisualizer.previewEffect("depth", false), "depth");
    compare(WallpaperVisualizer.previewEffect("", true), "waves");
    compare(WallpaperVisualizer.previewEffect("edges", true), "edges");
  }

  function test_hintKey() {
    compare(WallpaperVisualizer.hintKey(""), "");
    compare(WallpaperVisualizer.hintKey("nope"), "");
    for (const effect of ["waves", "depth", "edges"])
      verify(WallpaperVisualizer.hintKey(effect).startsWith("panels.desktop-widgets.effect-hint-"), effect);
  }

  // Regression: mirrored on each edge with the highs at the ends, the corners always got
  // the quietest bands and stayed empty
  function test_lobes_never_line_up_with_the_four_edges() {
    verify(WallpaperVisualizer.lobes % 2 === 1, "odd");
    verify(WallpaperVisualizer.lobes % 4 !== 0);
  }

  function test_frameLevel_is_full_for_any_real_song() {
    compare(WallpaperVisualizer.frameLevel([0.1, 0.45, 0.2], 0, 1 / 60, 0.3, 0.6), 1);
    fuzzyCompare(WallpaperVisualizer.frameLevel([0.15, 0.05], 0, 1 / 60, 0.3, 0.6), 0.5, 1e-9);
  }

  // The old floor was a fixed height, so when a song cut out a still frame stayed on screen
  function test_frameLevel_fades_out_when_the_song_goes_quiet() {
    fuzzyCompare(WallpaperVisualizer.frameLevel([0, 0], 1, 0.6, 0.3, 0.6), 0.5, 1e-9);
    let level = 1;
    for (let i = 0; i < 300; i++)
      level = WallpaperVisualizer.frameLevel([0, 0], level, 1 / 60, 0.3, 0.6);
    verify(level < 0.01, level);
  }

  function test_frameLevel_rises_at_once_and_ignores_bad_input() {
    compare(WallpaperVisualizer.frameLevel([0.3], 0.1, 0, 0.3, 0.6), 1);
    compare(WallpaperVisualizer.frameLevel([NaN, "x"], NaN, 1, 0.3, 0.6), 0);
    compare(WallpaperVisualizer.frameLevel(null, 0, 1, 0.3, 0.6), 0);
  }

  // Regression: one bump per spectrum band made narrow, crowded spikes
  function test_bins_average_the_spectrum_into_wide_bands() {
    compare(WallpaperVisualizer.bins([1, 0, 0.5, 0.5, 0.2, 0.4], 3), [0.5, 0.5, 0.30000000000000004]);
    compare(WallpaperVisualizer.bins([0.1, 0.2], 12), [0.1, 0.2]);
    compare(WallpaperVisualizer.bins(null, 12), []);
    compare(WallpaperVisualizer.bins([NaN, 1], 1), [0.5]);
    compare(WallpaperVisualizer.bins(new Array(32).fill(0.3), WallpaperVisualizer.waveBands).length, WallpaperVisualizer.waveBands);
  }

  function test_drift_is_slow_and_bounded() {
    let lo = 1, hi = -1;
    for (let t = 0; t < 600; t += 0.5) {
      const d = WallpaperVisualizer.drift(t);
      lo = Math.min(lo, d);
      hi = Math.max(hi, d);
      // Never faster than a fifth of a lobe a second
      verify(Math.abs(WallpaperVisualizer.drift(t + 0.5) - d) < 0.5 * 0.2 / WallpaperVisualizer.lobes, t);
    }
    verify(hi <= 0.36 && lo >= -0.36);
    // Wanders over more than a lobe, so every part of the border gets the lows
    verify(hi - lo > 1 / WallpaperVisualizer.lobes, hi - lo);
  }
}
