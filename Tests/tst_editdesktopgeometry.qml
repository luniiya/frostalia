import QtQuick
import QtTest
import "../Helpers/EditDesktopGeometry.js" as Geometry

TestCase {
  name: "EditDesktopGeometry"

  // ----- cardRect -----

  function test_cardRect_fitsAboveTheShelfAndKeepsTheAspect() {
    var r = Geometry.cardRect(2000, 1000, 40, 200);
    // available 1920 x 720, limited by the height: s = 0.72
    fuzzyCompare(r.s, 0.72, 1e-9);
    fuzzyCompare(r.width, 1440, 1e-9);
    fuzzyCompare(r.height, 720, 1e-9);
    fuzzyCompare(r.x, 280, 1e-9);
    fuzzyCompare(r.y, 40, 1e-9);
  }

  function test_cardRect_limitedByWidth() {
    var r = Geometry.cardRect(1000, 2000, 50, 100);
    // available 900 x 1800 -> s = min(0.9, 0.9) = 0.9
    fuzzyCompare(r.s, 0.9, 1e-9);
    fuzzyCompare(r.x, 50, 1e-9);
  }

  function test_cardRect_neverEnlarges() {
    compare(Geometry.cardRect(800, 600, 0, 0).s, 1);
  }

  function test_cardRect_isCenteredInTheFreeArea() {
    var r = Geometry.cardRect(2256, 1504, 60, 220);
    fuzzyCompare(r.x + r.width / 2, 2256 / 2, 1e-9);
    // the space above the card (pad) and below it (pad + tray) differ by the tray only
    fuzzyCompare((1504 - (r.y + r.height)) - r.y, 220, 1e-9);
  }

  function test_cardRect_degenerateInputs() {
    var r = Geometry.cardRect(0, 0, 10, 10);
    verify(r.s > 0 && isFinite(r.s));
    var big = Geometry.cardRect(100, 100, 400, 400);
    verify(big.s > 0 && isFinite(big.s));
  }

  // ----- stageTransform -----

  function test_stageTransform_endsOfTheAnimation() {
    var rect = Geometry.cardRect(2000, 1000, 40, 200);
    var start = Geometry.stageTransform(0, rect);
    compare(start.scale, 1);
    compare(start.x, 0);
    compare(start.y, 0);
    var end = Geometry.stageTransform(1, rect);
    fuzzyCompare(end.scale, rect.s, 1e-9);
    fuzzyCompare(end.x, rect.x, 1e-9);
    fuzzyCompare(end.y, rect.y, 1e-9);
  }

  function test_stageTransform_halfwayAndClamped() {
    var rect = {
      "x": 100,
      "y": 40,
      "s": 0.5,
      "width": 0,
      "height": 0
    };
    var mid = Geometry.stageTransform(0.5, rect);
    fuzzyCompare(mid.scale, 0.75, 1e-9);
    fuzzyCompare(mid.x, 50, 1e-9);
    // an overshooting easing curve (OutBack) is clamped by the caller, but NaN must not leak
    compare(Geometry.stageTransform(NaN, rect).scale, 1);
    compare(Geometry.stageTransform(-3, rect).scale, 1);
    fuzzyCompare(Geometry.stageTransform(7, rect).scale, 0.5, 1e-9);
  }

  // ----- toDesktop / spotFor -----

  function test_toDesktop_roundTripsWithTheCard() {
    var rect = Geometry.cardRect(2000, 1000, 40, 200);
    // the card's own top-left is the desktop origin, its bottom-right the desktop's far corner
    var origin = Geometry.toDesktop(rect.x, rect.y, rect, 2000, 1000);
    fuzzyCompare(origin.x, 0, 1e-9);
    fuzzyCompare(origin.y, 0, 1e-9);
    compare(origin.inside, true);
    var far = Geometry.toDesktop(rect.x + rect.width, rect.y + rect.height, rect, 2000, 1000);
    fuzzyCompare(far.x, 2000, 1e-6);
    fuzzyCompare(far.y, 1000, 1e-6);
    compare(far.inside, true);
  }

  function test_toDesktop_outsideTheCard() {
    var rect = Geometry.cardRect(2000, 1000, 40, 200);
    compare(Geometry.toDesktop(5, 5, rect, 2000, 1000).inside, false);
    compare(Geometry.toDesktop(rect.x + rect.width + 1, rect.y, rect, 2000, 1000).inside, false);
    // on the shelf, below the card
    compare(Geometry.toDesktop(1000, 950, rect, 2000, 1000).inside, false);
  }

  function test_spotFor_centersOnThePointAndStaysOnTheDesktop() {
    var p = Geometry.spotFor(200, 100, 1000, 500, 2000, 1000);
    compare(p.x, 900);
    compare(p.y, 450);
    var corner = Geometry.spotFor(200, 100, 5, 5, 2000, 1000);
    compare(corner.x, 0);
    compare(corner.y, 0);
    var farCorner = Geometry.spotFor(200, 100, 1995, 995, 2000, 1000);
    compare(farCorner.x, 1800);
    compare(farCorner.y, 900);
  }

  function test_spotFor_widgetBiggerThanTheDesktop() {
    var p = Geometry.spotFor(3000, 2000, 500, 500, 2000, 1000);
    compare(p.x, 0);
    compare(p.y, 0);
  }

  function test_ghostSize_followsTheCardScale() {
    var g = Geometry.ghostSize(200, 100, {
                                 "s": 0.5
                               });
    compare(g.width, 100);
    compare(g.height, 50);
  }

  // ----- gesture -----

  function test_gesture_data() {
    return [
      {
        "tag": "still",
        "dx": 0,
        "dy": 0,
        "expected": "click"
      },
      {
        "tag": "small wiggle",
        "dx": 3,
        "dy": -3,
        "expected": "click"
      },
      {
        "tag": "straight up",
        "dx": 0,
        "dy": -5,
        "expected": "pull"
      },
      {
        "tag": "steep up and across",
        "dx": 12,
        "dy": -9,
        "expected": "pull"
      },
      {
        "tag": "too flat is a scroll",
        "dx": 30,
        "dy": -10,
        "expected": "scroll"
      },
      {
        "tag": "downward is a scroll",
        "dx": 0,
        "dy": 20,
        "expected": "scroll"
      },
      {
        "tag": "sideways",
        "dx": -25,
        "dy": 2,
        "expected": "scroll"
      }
    ];
  }

  function test_gesture(data) {
    compare(Geometry.gesture(data.dx, data.dy), data.expected);
  }

  // ----- snap -----

  function test_snap_toAnotherWidgetsEdge() {
    var others = [
      {
        "x": 500,
        "y": 100,
        "width": 200,
        "height": 100
      }
    ];
    var moving = {
      "x": 296,
      "y": 400,
      "width": 200,
      "height": 100
    };
    // right edge 496 -> 500 (the other's left edge)
    var s = Geometry.snap(moving, others, 0, 8);
    compare(s.x, 300);
    compare(s.y, 400);
    compare(s.guides.length, 1);
    compare(s.guides[0].vertical, true);
    compare(s.guides[0].position, 500);
  }

  function test_snap_toCentersAlignsBothAxes() {
    var others = [
      {
        "x": 400,
        "y": 400,
        "width": 200,
        "height": 200
      }
    ];
    var moving = {
      "x": 905,
      "y": 100,
      "width": 100,
      "height": 100
    };
    // centers: x 955 vs 500 no; shift so that centers are near: not near here
    var far = Geometry.snap(moving, others, 0, 8);
    compare(far.x, 905);
    compare(far.guides.length, 0);
    var near = Geometry.snap({
                               "x": 446,
                               "y": 705,
                               "width": 100,
                               "height": 100
                             }, others, 0, 8);
    // center x 496 vs the other's center 500, top... y: 705 vs bottom edge 600 no, bottom 805 no
    compare(near.x, 450);
  }

  function test_snap_prefersTheClosestCandidate() {
    var others = [
      {
        "x": 300,
        "y": 0,
        "width": 100,
        "height": 100
      },
      {
        "x": 305,
        "y": 200,
        "width": 100,
        "height": 100
      }
    ];
    var s = Geometry.snap({
                            "x": 304,
                            "y": 500,
                            "width": 50,
                            "height": 50
                          }, others, 0, 8);
    compare(s.x, 305);
  }

  function test_snap_fallsBackToTheGrid() {
    var s = Geometry.snap({
                            "x": 137,
                            "y": 263,
                            "width": 50,
                            "height": 50
                          }, [], 25, 8);
    compare(s.x, 125);
    compare(s.y, 275);
    compare(s.guides.length, 0);
  }

  function test_snap_noGridNoOthersKeepsThePosition() {
    var s = Geometry.snap({
                            "x": 137,
                            "y": 263,
                            "width": 50,
                            "height": 50
                          }, [], 0, 8);
    compare(s.x, 137);
    compare(s.y, 263);
  }

  function test_snap_outsideTheThresholdDoesNotSnapToWidgets() {
    var s = Geometry.snap({
                            "x": 100,
                            "y": 100,
                            "width": 50,
                            "height": 50
                          }, [
                            {
                              "x": 200,
                              "y": 300,
                              "width": 50,
                              "height": 50
                            }
                          ], 0, 8);
    compare(s.x, 100);
    compare(s.y, 100);
  }

  // ----- clampPosition -----

  function test_clampPosition_keepsAQuarterVisible() {
    var p = Geometry.clampPosition(-500, 2000, 200, 100, 1000, 800);
    compare(p.x, -150); // -width + 25%
    compare(p.y, 775); // screen height - 25% of the height
    var inside = Geometry.clampPosition(300, 200, 200, 100, 1000, 800);
    compare(inside.x, 300);
    compare(inside.y, 200);
  }

  // ----- newWidget / tileIcon -----

  function test_newWidget_copiesTheDefaultsAndCentersOnThePoint() {
    var w = Geometry.newWidget("Clock", {
                                 "clockStyle": "analog",
                                 "scale": 3
                               }, 1000, 600, 2000, 1000);
    compare(w.id, "Clock");
    compare(w.clockStyle, "analog");
    compare(w.scale, 1.0, "a new widget starts at its natural size");
    compare(w.x, 900);
    compare(w.y, 540);
  }

  function test_newWidget_staysOnTheDesktopAndToleratesNoDefaults() {
    var w = Geometry.newWidget("plugin:timer", null, 5, 5, 2000, 1000);
    compare(w.id, "plugin:timer");
    compare(w.x, 0);
    compare(w.y, 0);
  }

  function test_tileIcon() {
    compare(Geometry.tileIcon("Clock"), "clock");
    compare(Geometry.tileIcon("plugin:timer"), "plug");
    compare(Geometry.tileIcon("Unknown"), "layout-grid-add");
  }
}
