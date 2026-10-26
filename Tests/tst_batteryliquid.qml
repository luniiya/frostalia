import QtQuick
import QtTest
import "../Helpers/BatteryLiquid.js" as BatteryLiquid

TestCase {
  name: "BatteryLiquid"

  function test_fillFraction_data() {
    return [
          {
            "percent": 0,
            "ready": true,
            "expected": 0
          },
          {
            "percent": 50,
            "ready": true,
            "expected": 0.5
          },
          {
            "percent": 100,
            "ready": true,
            "expected": 1
          },
          {
            "percent": 140,
            "ready": true,
            "expected": 1
          },
          {
            "percent": -5,
            "ready": true,
            "expected": 0
          },
          {
            "percent": 80,
            "ready": false,
            "expected": 0
          },
          {
            "percent": NaN,
            "ready": true,
            "expected": 0
          }
        ];
  }

  function test_fillFraction(data) {
    fuzzyCompare(BatteryLiquid.fillFraction(data.percent, data.ready), data.expected, 1e-9);
  }

  function test_liquidColorRole_data() {
    return [
          {
            "ready": true,
            "low": false,
            "critical": false,
            "expected": "primary"
          },
          {
            "ready": true,
            "low": true,
            "critical": false,
            "expected": "error"
          },
          {
            "ready": true,
            "low": false,
            "critical": true,
            "expected": "error"
          },
          {
            "ready": false,
            "low": true,
            "critical": true,
            "expected": "primary"
          }
        ];
  }

  function test_liquidColorRole(data) {
    compare(BatteryLiquid.liquidColorRole(data.ready, data.low, data.critical), data.expected);
  }

  function test_waveItemY_emptyHidesWaveBelowContainer() {
    var a = BatteryLiquid.waveAmplitude(28, 40);
    // crest of the wave (top of the item) must sit at or below the container bottom
    verify(BatteryLiquid.waveItemY(0, 40, a) >= 40);
  }

  function test_waveItemY_fullCoversContainer() {
    var a = BatteryLiquid.waveAmplitude(28, 40);
    var y = BatteryLiquid.waveItemY(1, 40, a);
    // the lowest point of the surface (item y + 2 * amplitude) is at or above the container top
    verify(y + 2 * a <= 0 + 1e-9);
  }

  function test_waveItemY_risesWithCharge() {
    var a = BatteryLiquid.waveAmplitude(28, 40);
    verify(BatteryLiquid.waveItemY(0.8, 40, a) < BatteryLiquid.waveItemY(0.2, 40, a));
  }

  function test_waveAmplitude_ignoresContainerLength() {
    // a taller container must not get taller waves
    compare(BatteryLiquid.waveAmplitude(28, 46), BatteryLiquid.waveAmplitude(28, 90));
    verify(BatteryLiquid.waveAmplitude(28, 90) < 2);
  }

  function test_waveAmplitude_hasMinimum() {
    compare(BatteryLiquid.waveAmplitude(10, 10), 1.2);
    verify(BatteryLiquid.waveAmplitude(100, 100) > 1.2);
  }

  function test_wavePolygon_loopsSeamlesslyAfterOneWavelength() {
    var pts = BatteryLiquid.wavePolygon(30, 2, 2, 60, 0, 16);
    // 2 periods * 16 steps + 1 surface points, plus the two bottom corners
    compare(pts.length, 33 + 2);
    // the surface at x and x + wavelength is identical
    fuzzyCompare(pts[0].y, pts[16].y, 1e-9);
    fuzzyCompare(pts[5].y, pts[21].y, 1e-9);
  }

  function test_wavePolygon_closesAlongTheBottom() {
    var pts = BatteryLiquid.wavePolygon(30, 2, 2, 60, 0);
    var n = pts.length;
    compare(pts[n - 2].x, 60);
    compare(pts[n - 2].y, 60);
    compare(pts[n - 1].x, 0);
    compare(pts[n - 1].y, 60);
  }

  function test_wavePolygon_surfaceStaysWithinAmplitude() {
    var pts = BatteryLiquid.wavePolygon(30, 2, 3, 60, 1.2);
    for (var i = 0; i < pts.length - 2; i++) {
      verify(pts[i].y >= -1e-9 && pts[i].y <= 6 + 1e-9);
    }
  }

  function test_containerLength() {
    compare(BatteryLiquid.containerLength(28), 90);
    compare(BatteryLiquid.containerLength(28, 1), 28);
  }

  function test_migrateDisplayMode_convertsIconAlways() {
    var sections = {
      "left": [
        {
          "id": "Clock"
        }
      ],
      "right": [
        {
          "id": "Battery",
          "displayMode": "icon-always",
          "hideIfIdle": false
        }
      ]
    };
    var migrated = BatteryLiquid.migrateDisplayMode(sections);
    compare(migrated.right[0].displayMode, "liquid");
    compare(migrated.right[0].hideIfIdle, false);
    compare(migrated.left[0].id, "Clock");
    // input is left untouched
    compare(sections.right[0].displayMode, "icon-always");
  }

  function test_migrateDisplayMode_leavesOtherModesAlone() {
    compare(BatteryLiquid.migrateDisplayMode({
                                               "right": [
                                                 {
                                                   "id": "Battery",
                                                   "displayMode": "graphic"
                                                 },
                                                 {
                                                   "id": "Volume",
                                                   "displayMode": "icon-always"
                                                 }
                                               ]
                                             }), null);
    compare(BatteryLiquid.migrateDisplayMode(null), null);
    compare(BatteryLiquid.migrateDisplayMode({
                                               "left": []
                                             }), null);
  }

  function test_migrateDisplayMode_acceptsArrayLikeLists() {
    // lists read from the settings file are not always real Arrays
    var list = {
      "length": 2,
      "0": {
        "id": "Clock"
      },
      "1": {
        "id": "Battery",
        "displayMode": "icon-always"
      }
    };
    var migrated = BatteryLiquid.migrateDisplayMode({
                                                      "right": list
                                                    });
    compare(migrated.right.length, 2);
    compare(migrated.right[1].displayMode, "liquid");
    compare(migrated.right[0].id, "Clock");
  }

  // rand stub: always returns the given value
  function constant(v) {
    return function () {
      return v;
    };
  }

  function test_bubbleSpec_staysInsideTheContainer_data() {
    return [
      {
        "r": 0
      },
      {
        "r": 0.5
      },
      {
        "r": 0.999
      }
    ];
  }

  function test_bubbleSpec_staysInsideTheContainer(data) {
    var spec = BatteryLiquid.bubbleSpec(constant(data.r), 28, 30);
    verify(spec.size >= 1.5);
    verify(spec.x - spec.size / 2 >= 0);
    verify(spec.x + spec.size / 2 <= 28);
    verify(spec.wobble <= 2.5);
  }

  function test_bubbleSpec_restsBetweenRises() {
    var spec = BatteryLiquid.bubbleSpec(constant(0), 28, 30);
    verify(spec.rest >= 1500);
    verify(spec.duration >= 2800);
  }

  function test_bubbleSpec_variesWithTheRandomSource() {
    var a = BatteryLiquid.bubbleSpec(constant(0.1), 28, 30);
    var b = BatteryLiquid.bubbleSpec(constant(0.9), 28, 30);
    verify(a.size < b.size);
    verify(a.duration < b.duration);
  }

  function test_bubbleSpec_narrowContainerDoesNotGoNegative() {
    var spec = BatteryLiquid.bubbleSpec(constant(0.7), 2, 30);
    verify(isFinite(spec.x));
    verify(spec.wobble >= 0);
  }

  function test_bubblePosition_risesFromBelowToAboveTheLiquid() {
    var spec = {
      "size": 4,
      "x": 10,
      "wobble": 2,
      "cycles": 1,
      "duration": 3000,
      "rest": 5000
    };
    var start = BatteryLiquid.bubblePosition(spec, 0, 30);
    var end = BatteryLiquid.bubblePosition(spec, 1, 30);
    fuzzyCompare(start.y, 32, 1e-9);
    fuzzyCompare(end.y, -2, 1e-9);
    var mid = BatteryLiquid.bubblePosition(spec, 0.5, 30);
    verify(mid.y < start.y && mid.y > end.y);
    // wobble keeps the bubble within its range
    verify(Math.abs(mid.x - 10) <= 2 + 1e-9);
  }

  function test_bubbleOpacity_fadesInAndOutAndIsFaint() {
    compare(BatteryLiquid.bubbleOpacity(0, 0.3), 0);
    compare(BatteryLiquid.bubbleOpacity(1, 0.3), 0);
    fuzzyCompare(BatteryLiquid.bubbleOpacity(0.5, 0.3), 0.3, 1e-9);
    verify(BatteryLiquid.bubbleOpacity(0.05, 0.3) < 0.3);
    verify(BatteryLiquid.bubbleOpacity(0.95, 0.3) < 0.3);
  }
}
