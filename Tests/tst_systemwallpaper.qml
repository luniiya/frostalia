import QtQuick
import QtTest
import "../Helpers/SystemWallpaper.js" as SystemWallpaper

TestCase {
  name: "SystemWallpaper"

  function test_parseQuery_data() {
    return [
          {
            tag: "awww",
            out: ": eDP-1: 2256x1504, scale: 1, currently displaying: image: /home/u/Wall/a b.png\n",
            e: {
              "eDP-1": "/home/u/Wall/a b.png"
            }
          },
          {
            tag: "swww (no prefix)",
            out: "DP-2: 2560x1440, scale: 1, currently displaying: image: /w/x.jpg",
            e: {
              "DP-2": "/w/x.jpg"
            }
          },
          {
            tag: "multi monitor",
            out: ": eDP-1: 1x1, scale: 1, currently displaying: image: /a.png\n: HDMI-A-1: 1x1, scale: 1, currently displaying: image: /b.png",
            e: {
              "eDP-1": "/a.png",
              "HDMI-A-1": "/b.png"
            }
          },
          {
            tag: "solid color skipped",
            out: ": eDP-1: 1x1, scale: 1, currently displaying: color: 000000",
            e: {}
          },
          {
            tag: "hyprpaper",
            out: "eDP-1 = /home/u/w.png\nDP-1 = /home/u/v.png",
            e: {
              "eDP-1": "/home/u/w.png",
              "DP-1": "/home/u/v.png"
            }
          },
          {
            tag: "daemon error",
            out: "Error: failed to connect to the socket",
            e: {}
          },
          {
            tag: "empty",
            out: "",
            e: {}
          },
          {
            tag: "undefined",
            out: undefined,
            e: {}
          }
        ];
  }
  function test_parseQuery(d) {
    compare(SystemWallpaper.parseQuery(d.out), d.e);
  }

  function test_changedScreens() {
    compare(SystemWallpaper.changedScreens({}, {
                                             "eDP-1": "/a"
                                           }), ["eDP-1"]);
    compare(SystemWallpaper.changedScreens({
                                             "eDP-1": "/a"
                                           }, {
                                             "eDP-1": "/a"
                                           }), []);
    compare(SystemWallpaper.changedScreens({
                                             "eDP-1": "/a"
                                           }, {
                                             "eDP-1": "/b"
                                           }), ["eDP-1"]);
    compare(SystemWallpaper.changedScreens({
                                             "eDP-1": "/a",
                                             "DP-1": "/c"
                                           }, {
                                             "eDP-1": "/a"
                                           }), []);
    compare(SystemWallpaper.changedScreens(undefined, {
                                             "eDP-1": "/a"
                                           }), ["eDP-1"]);
  }

  function test_wallpaperFor() {
    var w = {
      "eDP-1": "/a",
      "DP-1": "/b"
    };
    compare(SystemWallpaper.wallpaperFor(w, "DP-1"), "/b");
    compare(SystemWallpaper.wallpaperFor(w, "HDMI-A-1"), "/a");
    compare(SystemWallpaper.wallpaperFor(w, ""), "/a");
    compare(SystemWallpaper.wallpaperFor({}, "eDP-1"), "");
    compare(SystemWallpaper.wallpaperFor(undefined, "eDP-1"), "");
  }
}
