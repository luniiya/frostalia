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
    compare(WallpaperVisualizer.nextEdges("topBottom"), "bottom");
    compare(WallpaperVisualizer.nextEdges("bottom"), "all");
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

  function test_equalize_silence_stays_silent() {
    const r = WallpaperVisualizer.equalize([0, 0, 0.01], [], 0, 2, 0.08);
    verify(r.values[0] === 0 && r.values[1] === 0);
    // Noise under the floor is not blown up to full height
    verify(r.values[2] < 0.2, r.values[2]);
  }

  // Regression: highs carry far less energy than lows, so the corners (where the
  // mirrored spectrum puts them) barely moved
  function test_equalize_quiet_bands_use_their_full_range() {
    let peaks = [];
    let r = null;
    for (let i = 0; i < 20; i++) {
      r = WallpaperVisualizer.equalize([0.9, 0.2], peaks, 1 / 60, 2, 0.08);
      peaks = r.peaks;
    }
    fuzzyCompare(r.values[0], 1, 1e-9);
    fuzzyCompare(r.values[1], 1, 1e-9);
  }

  function test_equalize_peaks_decay_by_half_life() {
    const r = WallpaperVisualizer.equalize([0], [0.8], 2, 2, 0.08);
    fuzzyCompare(r.peaks[0], 0.4, 1e-9);
    const floor = WallpaperVisualizer.equalize([0], [0.1], 100, 2, 0.08);
    fuzzyCompare(floor.peaks[0], 0.08, 1e-9);
  }

  function test_equalize_follows_a_drop_after_a_loud_peak() {
    let peaks = [1];
    let r = WallpaperVisualizer.equalize([0.3], peaks, 0, 2, 0.08);
    fuzzyCompare(r.values[0], 0.3, 1e-9);
    // Four half-lives later the same level reads as loud again
    r = WallpaperVisualizer.equalize([0.3], r.peaks, 8, 2, 0.08);
    fuzzyCompare(r.values[0], 1, 1e-9);
  }

  function test_equalize_bad_input() {
    const r = WallpaperVisualizer.equalize([NaN, -1, 2, "x"], null, 0, 2, 0.08);
    compare(r.values, [0, 0, 1, 0]);
    compare(r.peaks.length, 4);
  }
}
