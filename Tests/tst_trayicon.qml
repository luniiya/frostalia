import QtQuick
import QtTest
import "../Helpers/TrayIcon.js" as TrayIcon

TestCase {
  name: "TrayIcon"

  // Fake icon theme: only these names exist
  function lookupIn(names) {
    return function (n) {
      return names.indexOf(n) !== -1 ? "image://icon/" + n : "";
    };
  }

  // ----- sourceFromIcon / themeIconName -----

  function test_sourceFromIcon_keepsPlainSources() {
    compare(TrayIcon.sourceFromIcon(""), "");
    compare(TrayIcon.sourceFromIcon(undefined), "");
    compare(TrayIcon.sourceFromIcon("image://icon/vicinae"), "image://icon/vicinae");
    compare(TrayIcon.sourceFromIcon("image://qsimage/abc/1"), "image://qsimage/abc/1");
  }

  function test_sourceFromIcon_usesItemIconPath() {
    compare(TrayIcon.sourceFromIcon("image://icon/steam_tray?path=/opt/steam/icons"), "file:///opt/steam/icons/steam_tray");
  }

  function test_themeIconName() {
    compare(TrayIcon.themeIconName("image://icon/input-keyboard-symbolic"), "input-keyboard-symbolic");
    compare(TrayIcon.themeIconName("image://icon/foo?fallback=bar"), "foo");
    compare(TrayIcon.themeIconName("image://qsimage/abc/1"), "");
    compare(TrayIcon.themeIconName("file:///tmp/x.png"), "");
    compare(TrayIcon.themeIconName(""), "");
  }

  // ----- candidateNames -----

  function test_candidateNames_order() {
    compare(TrayIcon.candidateNames("input-keyboard-symbolic", "Fcitx", "Input Method"), ["input-keyboard-symbolic", "input-keyboard", "fcitx", "input method", "input-method"]);
  }

  function test_candidateNames_stripsThemeVariantSuffix() {
    var names = TrayIcon.candidateNames("kdeconnectindicatordark", "", "");
    compare(names, ["kdeconnectindicatordark", "kdeconnectindicator"]);
    compare(TrayIcon.candidateNames("app-light-symbolic", "", ""), ["app-light-symbolic", "app-light", "app"]);
  }

  function test_candidateNames_reverseDomainId() {
    var names = TrayIcon.candidateNames("", "shelly.shellyorg.Notifications", "");
    compare(names, ["shelly.shellyorg.notifications", "notifications"]);
  }

  function test_candidateNames_noDuplicatesOrEmpties() {
    compare(TrayIcon.candidateNames("vicinae", "vicinae", "Vicinae"), ["vicinae"]);
    compare(TrayIcon.candidateNames("", undefined, null), []);
    compare(TrayIcon.candidateNames("", "  ", ""), []);
  }

  // ----- resolve -----

  function test_resolve_existingIconUnchanged() {
    compare(TrayIcon.resolve("image://icon/vicinae", "vicinae", "Vicinae", lookupIn(["vicinae"])), "image://icon/vicinae");
  }

  function test_resolve_fcitxFallsBackToAppId() {
    // Regression: the theme lacks input-keyboard-symbolic, which showed the
    // magenta/black "missing" checkerboard in the tray
    compare(TrayIcon.resolve("image://icon/input-keyboard-symbolic", "Fcitx", "Input Method", lookupIn(["fcitx"])), "image://icon/fcitx");
  }

  function test_resolve_prefersNonSymbolicOverAppId() {
    compare(TrayIcon.resolve("image://icon/input-keyboard-symbolic", "Fcitx", "", lookupIn(["fcitx", "input-keyboard"])), "image://icon/input-keyboard");
  }

  function test_resolve_nothingFoundReturnsEmpty() {
    compare(TrayIcon.resolve("image://icon/nope-symbolic", "Nope", "", lookupIn([])), "");
  }

  function test_resolve_passesPixmapsAndFilesThrough() {
    var never = function () {
      fail("lookup must not be called for non-theme sources");
    };
    compare(TrayIcon.resolve("image://qsimage/vesktop/3", "vesktop", "", never), "image://qsimage/vesktop/3");
    compare(TrayIcon.resolve("image://icon/a?path=/icons", "a", "", never), "file:///icons/a");
    compare(TrayIcon.resolve("", "a", "", never), "");
  }

  function test_resolve_usesLookupResultVerbatim() {
    var lookup = function (n) {
      return n === "fcitx" ? "file:///usr/share/icons/fcitx.svg" : "";
    };
    compare(TrayIcon.resolve("image://icon/x", "Fcitx", "", lookup), "file:///usr/share/icons/fcitx.svg");
  }

  // ----- colorize -----

  function test_normalizeStyle() {
    compare(TrayIcon.normalizeStyle("duotone"), "duotone");
    compare(TrayIcon.normalizeStyle("monochrome"), "monochrome");
    compare(TrayIcon.normalizeStyle(undefined), "monochrome");
    compare(TrayIcon.normalizeStyle("rainbow"), "monochrome");
  }

  function test_colorizeParams_monochromeContrastsWithBarInBothModes() {
    // Regression: light mode used mSurfaceVariant, nearly the bar's own color,
    // then a single mOnSurface, which turned every icon into a black blob
    compare(TrayIcon.colorizeParams("monochrome", true), {
              "mode": 3.0,
              "lowRole": "mOnSurfaceVariant",
              "highRole": "mOnSurface"
            });
    compare(TrayIcon.colorizeParams(undefined, false), {
              "mode": 3.0,
              "lowRole": "mOnSurface",
              "highRole": "mOnSurfaceVariant"
            });
  }

  function test_colorizeParams_duotoneDarkPixelsGetDarkerColor() {
    // Dark theme: mOnSurface is the brightest role, light theme: the darkest
    compare(TrayIcon.colorizeParams("duotone", true), {
              "mode": 3.0,
              "lowRole": "mPrimary",
              "highRole": "mOnSurface"
            });
    compare(TrayIcon.colorizeParams("duotone", false), {
              "mode": 3.0,
              "lowRole": "mOnSurface",
              "highRole": "mPrimary"
            });
  }
}
