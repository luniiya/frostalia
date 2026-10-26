import QtQuick
import QtTest
import "../Helpers/LauncherView.js" as View

TestCase {
  name: "LauncherView"

  function test_iconKind_data() {
    return [
          {
            "tag": "display string wins",
            "item": {
              "displayString": "😀",
              "icon": "smile",
              "isTablerIcon": true
            },
            "mode": "tabler",
            "failed": false,
            "expected": "string"
          },
          {
            "tag": "color swatch",
            "item": {
              "colorHex": "#ff0000",
              "isImage": true
            },
            "mode": "tabler",
            "failed": false,
            "expected": "color"
          },
          {
            "tag": "image",
            "item": {
              "isImage": true,
              "icon": "image"
            },
            "mode": "tabler",
            "failed": false,
            "expected": "image"
          },
          {
            "tag": "failed image falls back to icon",
            "item": {
              "isImage": true,
              "icon": "image",
              "isTablerIcon": true
            },
            "mode": "tabler",
            "failed": true,
            "expected": "glyph"
          },
          {
            "tag": "tabler glyph",
            "item": {
              "icon": "lock",
              "isTablerIcon": true
            },
            "mode": "tabler",
            "failed": false,
            "expected": "glyph"
          },
          {
            "tag": "native icon mode uses theme icons",
            "item": {
              "icon": "lock",
              "isTablerIcon": true
            },
            "mode": "native",
            "failed": false,
            "expected": "app"
          },
          {
            "tag": "app icon",
            "item": {
              "icon": "firefox"
            },
            "mode": "tabler",
            "failed": false,
            "expected": "app"
          },
          {
            "tag": "nothing",
            "item": {
              "name": "x"
            },
            "mode": "tabler",
            "failed": false,
            "expected": "letter"
          },
          {
            "tag": "null",
            "item": null,
            "mode": "tabler",
            "failed": false,
            "expected": "letter"
          }
        ];
  }

  function test_iconKind(data) {
    compare(View.iconKind(data.item, data.mode, data.failed), data.expected);
  }

  function test_letterFor() {
    compare(View.letterFor("firefox"), "F");
    compare(View.letterFor("  zed"), "Z");
    compare(View.letterFor(""), "?");
    compare(View.letterFor(undefined), "?");
  }

  function test_cycleIndex() {
    compare(View.cycleIndex(0, 1, 3), 1);
    compare(View.cycleIndex(2, 1, 3), 0);
    compare(View.cycleIndex(0, -1, 3), 2);
    compare(View.cycleIndex(-1, 1, 3), 0); // unknown current starts at the first entry
    compare(View.cycleIndex(-1, -1, 3), 2);
    compare(View.cycleIndex(0, 1, 0), -1);
  }

  function test_groupRadii_horizontal() {
    const first = View.groupRadii(0, 3, 40, 20, 8, false, false);
    compare([first.tl, first.bl, first.tr, first.br], [20, 20, 8, 8]);
    const middle = View.groupRadii(1, 3, 40, 20, 8, false, false);
    compare([middle.tl, middle.bl, middle.tr, middle.br], [8, 8, 8, 8]);
    const last = View.groupRadii(2, 3, 40, 20, 8, false, false);
    compare([last.tl, last.bl, last.tr, last.br], [8, 8, 20, 20]);
    const only = View.groupRadii(0, 1, 40, 20, 8, false, false);
    compare([only.tl, only.bl, only.tr, only.br], [20, 20, 20, 20]);
  }

  function test_groupRadii_vertical_and_selected() {
    const first = View.groupRadii(0, 3, 50, 20, 6, false, true);
    compare([first.tl, first.tr, first.bl, first.br], [20, 20, 6, 6]);
    const last = View.groupRadii(2, 3, 50, 20, 6, false, true);
    compare([last.tl, last.tr, last.bl, last.br], [6, 6, 20, 20]);
    const selected = View.groupRadii(1, 3, 50, 20, 6, true, true);
    compare([selected.tl, selected.tr, selected.bl, selected.br], [25, 25, 25, 25]);
    // Radii never exceed half the size
    const small = View.groupRadii(0, 2, 10, 20, 8, false, false);
    compare(small.tl, 5);
  }

  function test_gridCell() {
    const cell = View.gridCell(500, 5, 1);
    compare(cell.width, 100);
    compare(cell.height, 100);
    compare(View.gridCell(700, 7, 1.15).height, 115);
    compare(View.gridCell(300, 0, 0).width, 300);
  }

  function test_previewY() {
    compare(View.previewY(50, 0, 600, 400, 10), 50);
    compare(View.previewY(-30, 0, 600, 400, 10), 10);
    compare(View.previewY(500, 0, 600, 400, 10), 190);
    compare(View.previewY(500, 100, 600, 400, 10), 290);
  }

  function test_footerState() {
    compare(View.footerState(3, "", "").kind, "count");
    compare(View.footerState(3, "", "").count, 3);
    compare(View.footerState(0, "fire", "msg").kind, "empty");
    compare(View.footerState(0, "", "No recent").kind, "message");
    compare(View.footerState(0, "", "").kind, "none");
  }

  function test_popDelay() {
    compare(View.popDelay(0, 20, 8), 0);
    compare(View.popDelay(3, 20, 8), 60);
    compare(View.popDelay(50, 20, 8), 160);
  }

  function test_tiltFor() {
    const a = View.tiltFor("Pinned", 4);
    compare(View.tiltFor("Pinned", 4), a); // stable
    verify(Math.abs(a) <= 4);
    verify(Math.abs(a) >= 4 / 3);
    compare(View.tiltFor("anything", 0), 0);
  }

  function test_searchGlyph() {
    compare(View.searchGlyph(">"), "terminal-2");
    compare(View.searchGlyph("fire"), "search");
  }

  function test_modeAvailable() {
    verify(View.modeAvailable("clipboard", true));
    verify(!View.modeAvailable("clipboard", false));
    verify(View.modeAvailable("emoji", false));
    verify(!View.modeAvailable("nope", true));
  }

  function test_availableModes() {
    const withClip = View.availableModes(true).map(m => m.id);
    compare(withClip, ["apps", "windows", "clipboard", "emoji", "settings", "commands"]);
    verify(View.availableModes(false).map(m => m.id).indexOf("clipboard") < 0);
    compare(View.modeById("nope").id, "apps");
  }

  function test_splitQuery_data() {
    return [
          {
            "tag": "plain",
            "text": "fire",
            "mode": "apps",
            "query": "fire"
          },
          {
            "tag": "empty",
            "text": "",
            "mode": "apps",
            "query": ""
          },
          {
            "tag": "bare prefix",
            "text": ">clip",
            "mode": "clipboard",
            "query": ""
          },
          {
            "tag": "prefix with space",
            "text": ">clip ",
            "mode": "clipboard",
            "query": ""
          },
          {
            "tag": "prefix with query",
            "text": ">emoji smile",
            "mode": "emoji",
            "query": "smile"
          },
          {
            "tag": "query keeps inner spaces",
            "text": ">cmd ls -la",
            "mode": "commands",
            "query": "ls -la"
          },
          {
            "tag": "command list stays in apps",
            "text": ">",
            "mode": "apps",
            "query": ">"
          },
          {
            "tag": "partial prefix stays in apps",
            "text": ">cli",
            "mode": "apps",
            "query": ">cli"
          },
          {
            "tag": "prefix must end at a word",
            "text": ">window",
            "mode": "apps",
            "query": ">window"
          }
        ];
  }

  function test_splitQuery(data) {
    const r = View.splitQuery(data.text);
    compare(r.mode, data.mode);
    compare(r.query, data.query);
  }

  function test_joinQuery_roundTrip() {
    compare(View.joinQuery("apps", "fire"), "fire");
    compare(View.joinQuery("clipboard", ""), ">clip ");
    compare(View.joinQuery("emoji", "cat"), ">emoji cat");
    const modes = ["apps", "windows", "clipboard", "emoji", "settings", "commands"];
    for (let i = 0; i < modes.length; i++) {
      const r = View.splitQuery(View.joinQuery(modes[i], "x y"));
      compare(r.mode, modes[i]);
      compare(r.query, "x y");
    }
  }

  function test_sectionLetter() {
    const names = ["Anki", "alacritty", "Blender", "2048", "7zip", "zed"];
    compare(View.sectionLetter(names, 0), "A");
    compare(View.sectionLetter(names, 1), ""); // same initial, any case
    compare(View.sectionLetter(names, 2), "B");
    compare(View.sectionLetter(names, 3), "#");
    compare(View.sectionLetter(names, 4), ""); // digits group together
    compare(View.sectionLetter(names, 5), "Z");
    compare(View.sectionLetter(names, 9), "");
    compare(View.sectionLetter(null, 0), "");
  }

  function test_panelSize() {
    compare(View.panelSize(1).width, 740);
    compare(View.panelSize(1).height, 640);
    compare(View.panelSize(1.5).width, 1110);
    compare(View.panelSize(0).width, 740);
  }
}
