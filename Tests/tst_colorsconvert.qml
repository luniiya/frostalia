import QtQuick
import QtTest
import "../Helpers/ColorsConvert.js" as ColorsConvert

TestCase {
  name: "ColorsConvert"

  function test_hexToRgb() {
    var c = ColorsConvert.hexToRgb("#ff8000");
    compare(c.r, 255);
    compare(c.g, 128);
    compare(c.b, 0);
    c = ColorsConvert.hexToRgb("00FF7f"); // no hash, mixed case
    compare(c.g, 255);
    compare(c.b, 127);
  }

  function test_hexToRgb_invalidFallsBackToBlack() {
    var c = ColorsConvert.hexToRgb("not a color");
    compare(c.r, 0);
    compare(c.g, 0);
    compare(c.b, 0);
    c = ColorsConvert.hexToRgb("#fff"); // short form is not supported
    compare(c.r, 0);
  }

  function test_rgbToHex() {
    compare(ColorsConvert.rgbToHex(255, 128, 0), "#ff8000");
    compare(ColorsConvert.rgbToHex(0, 0, 0), "#000000");
    compare(ColorsConvert.rgbToHex(1, 2, 3), "#010203");
  }

  function test_rgbToHex_clampsAndRounds() {
    compare(ColorsConvert.rgbToHex(300, -5, 0), "#ff0000");
    compare(ColorsConvert.rgbToHex(127.6, 0.4, 0), "#800000");
  }

  function test_rgbToHsl() {
    var hsl = ColorsConvert.rgbToHsl(255, 0, 0);
    compare(hsl.h, 0);
    compare(hsl.s, 100);
    compare(hsl.l, 50);
    hsl = ColorsConvert.rgbToHsl(128, 128, 128); // grey has no hue/saturation
    compare(hsl.h, 0);
    compare(hsl.s, 0);
    hsl = ColorsConvert.rgbToHsl(0, 0, 255);
    compare(hsl.h, 240);
  }

  function test_hslToRgb() {
    var rgb = ColorsConvert.hslToRgb(120, 100, 50);
    compare(rgb.r, 0);
    compare(rgb.g, 255);
    compare(rgb.b, 0);
    rgb = ColorsConvert.hslToRgb(0, 0, 100);
    compare(rgb.r, 255);
    compare(rgb.g, 255);
    compare(rgb.b, 255);
  }

  function test_hexHslRoundTrip_data() {
    return ["#ff0000", "#00ff00", "#0000ff", "#123456", "#abcdef", "#808080", "#ffffff", "#000000", "#c0ffee"].map(h => ({
      "tag": h,
      "hex": h
    }));
  }

    function test_hexHslRoundTrip(data) {
    var hsl = ColorsConvert.hexToHSL(data.hex);
    compare(ColorsConvert.hslToHex(hsl.h, hsl.s, hsl.l), data.hex);
  }

    function test_hsvRoundTrip_data() {
    return [[255, 0, 0], [0, 255, 0], [0, 0, 255], [18, 52, 86], [200, 150, 100], [255, 255, 255], [0, 0, 0]].map(c => ({
    "tag": c.join(","),
    "c": c
  }));
  }

    function test_hsvRoundTrip(data) {
    var hsv = ColorsConvert.rgbToHsv(data.c[0], data.c[1], data.c[2]);
    var rgb = ColorsConvert.hsvToRgb(hsv.h, hsv.s, hsv.v);
    compare(rgb.r, data.c[0]);
    compare(rgb.g, data.c[1]);
    compare(rgb.b, data.c[2]);
  }

    function test_rgbToHsv() {
    var hsv = ColorsConvert.rgbToHsv(255, 0, 0);
    compare(hsv.h, 0);
    compare(hsv.s, 100);
    compare(hsv.v, 100);
    hsv = ColorsConvert.rgbToHsv(0, 0, 0);
    compare(hsv.s, 0);
    compare(hsv.v, 0);
  }

    function test_luminanceAndContrast() {
    fuzzyCompare(ColorsConvert.getLuminance("#ffffff"), 1, 1e-9);
    fuzzyCompare(ColorsConvert.getLuminance("#000000"), 0, 1e-9);
    fuzzyCompare(ColorsConvert.getContrastRatio("#000000", "#ffffff"), 21, 1e-6);
    fuzzyCompare(ColorsConvert.getContrastRatio("#ffffff", "#000000"), 21, 1e-6); // order independent
    fuzzyCompare(ColorsConvert.getContrastRatio("#777777", "#777777"), 1, 1e-9);
  }

    function test_isLightColor() {
    verify(ColorsConvert.isLightColor("#ffffff"));
    verify(ColorsConvert.isLightColor("#ffff00"));
    verify(!ColorsConvert.isLightColor("#000000"));
    verify(!ColorsConvert.isLightColor("#0000ff"));
  }

    function test_adjustLightness() {
    compare(ColorsConvert.adjustLightness("#808080", 100), "#ffffff");
    compare(ColorsConvert.adjustLightness("#808080", -100), "#000000");
    var lighter = ColorsConvert.hexToHSL(ColorsConvert.adjustLightness("#336699", 10));
    var base = ColorsConvert.hexToHSL("#336699");
    verify(lighter.l > base.l);
  }

    function test_adjustSaturation() {
    var grey = ColorsConvert.hexToHSL(ColorsConvert.adjustSaturation("#336699", -100));
    compare(grey.s, 0);
  }

    function test_adjustLightnessAndSaturation() {
    compare(ColorsConvert.adjustLightnessAndSaturation("#336699", 100, 0), "#ffffff");
    var out = ColorsConvert.hexToHSL(ColorsConvert.adjustLightnessAndSaturation("#336699", 0, -100));
    compare(out.s, 0);
  }

    function test_generateOnColor() {
    compare(ColorsConvert.generateOnColor("#ffffff", false), "#000000");
    compare(ColorsConvert.generateOnColor("#000000", true), "#ffffff");
    compare(ColorsConvert.generateOnColor("#1e3a8a", true), "#ffffff");
  }

    function test_generateOnColor_alwaysReadable_data() {
    return ["#ffffff", "#000000", "#ff0000", "#00ff00", "#0000ff", "#ffff00", "#808080", "#1e3a8a", "#fde68a"].map(h => ({
    "tag": h,
    "hex": h
  }));
  }

    function test_generateOnColor_alwaysReadable(data) {
    var on = ColorsConvert.generateOnColor(data.hex, true);
    verify(ColorsConvert.getContrastRatio(data.hex, on) >= 3, data.hex + " vs " + on);
  }

    function test_generateContainerColor() {
    var dark = ColorsConvert.hexToHSL(ColorsConvert.generateContainerColor("#6750a4", true));
    verify(dark.l >= 9.5 && dark.l <= 30.5, "dark container lightness " + dark.l);
    var light = ColorsConvert.hexToHSL(ColorsConvert.generateContainerColor("#6750a4", false));
    verify(light.l >= 74.5 && light.l <= 90.5, "light container lightness " + light.l);
  }

    function test_generateSurfaceVariant() {
    var base = ColorsConvert.hexToHSL("#303030").l;
    verify(ColorsConvert.hexToHSL(ColorsConvert.generateSurfaceVariant("#303030", 2, true)).l > base);
    verify(ColorsConvert.hexToHSL(ColorsConvert.generateSurfaceVariant("#303030", 2, false)).l < base);
    compare(ColorsConvert.generateSurfaceVariant("#303030", 0, true), "#303030");
  }
  }
