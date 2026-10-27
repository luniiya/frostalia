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
}
