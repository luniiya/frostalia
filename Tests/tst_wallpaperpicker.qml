import QtQuick
import QtTest
import "../Helpers/WallpaperPicker.js" as WallpaperPicker

TestCase {
  name: "WallpaperPicker"

  function entry(name, color, mtime, ext) {
    return {
      "path": "/w/" + name + "." + (ext || "png"),
      "name": name,
      "ext": ext || "png",
      "mtime": mtime || 0,
      "color": color === undefined ? null : color,
      "thumb": null
    };
  }

  // Color families ------------------------------------------------------

  function test_family_data() {
    return [
          {
            tag: "red",
            color: "#e01010",
            family: "red"
          },
          {
            tag: "red past 345",
            color: "#ff0020",
            family: "red"
          },
          {
            tag: "orange",
            color: "#ff8000",
            family: "orange"
          },
          {
            tag: "yellow",
            color: "#e0d020",
            family: "yellow"
          },
          {
            tag: "green",
            color: "#30a040",
            family: "green"
          },
          {
            tag: "teal",
            color: "#20b0b0",
            family: "teal"
          },
          {
            tag: "blue",
            color: "#1428dc",
            family: "blue"
          },
          {
            tag: "purple",
            color: "#8030d0",
            family: "purple"
          },
          {
            tag: "pink",
            color: "#e040a0",
            family: "pink"
          },
          {
            tag: "black",
            color: "#151515",
            family: "black"
          },
          {
            tag: "gray",
            color: "#7a7a80",
            family: "gray"
          },
          {
            tag: "white",
            color: "#eeeeee",
            family: "white"
          },
          {
            tag: "faint tint stays neutral",
            color: "#808a80",
            family: "gray"
          },
          {
            tag: "no color yet",
            color: null,
            family: ""
          },
          {
            tag: "garbage",
            color: "blue",
            family: ""
          }
        ];
  }

  function test_family(data) {
    compare(WallpaperPicker.family(data.color), data.family);
  }

  function test_every_family_has_a_swatch_in_its_own_family() {
    for (const f of WallpaperPicker.families)
      compare(WallpaperPicker.family(f.swatch), f.key, f.key);
  }

  function test_family_counts() {
    const counts = WallpaperPicker.familyCounts([entry("a", "#1428dc"), entry("b", "#1030c0"), entry("c", "#111111"), entry("d")]);
    compare(counts.blue, 2);
    compare(counts.black, 1);
    compare(counts.red, 0);
    compare(Object.keys(counts).length, WallpaperPicker.families.length);
  }

  // Search ---------------------------------------------------------------

  function test_matches_data() {
    return [
          {
            tag: "empty query",
            name: "anything",
            query: "  ",
            result: true
          },
          {
            tag: "case insensitive",
            name: "A_SNOW_COVERED_ROAD",
            query: "snow",
            result: true
          },
          {
            tag: "words in any order",
            name: "blue japan city",
            query: "city blue",
            result: true
          },
          {
            tag: "all words needed",
            name: "blue japan city",
            query: "blue forest",
            result: false
          },
          {
            tag: "inside a word",
            name: "mountains",
            query: "tain",
            result: true
          },
          {
            tag: "separators in the query",
            name: "snow covered road",
            query: "snow_covered",
            result: true
          },
          {
            tag: "no match",
            name: "red sky",
            query: "green",
            result: false
          }
        ];
  }

  function test_matches(data) {
    compare(WallpaperPicker.matches(data.name, data.query), data.result);
  }

  // Sorting and filtering -----------------------------------------------

  function names(list) {
    return list.map(e => e.name).join(",");
  }

  function test_sort_by_name_is_natural() {
    const list = [entry("wall10"), entry("Wall2"), entry("apple")];
    compare(names(WallpaperPicker.sorted(list, "name")), "apple,Wall2,wall10");
    // The input is not modified
    compare(names(list), "wall10,Wall2,apple");
  }

  function test_sort_by_date_is_newest_first() {
    const list = [entry("old", null, 10), entry("new", null, 30), entry("mid", null, 20)];
    compare(names(WallpaperPicker.sorted(list, "date")), "new,mid,old");
  }

  function test_sort_by_hue() {
    const list = [entry("none"), entry("white", "#f0f0f0"), entry("blue", "#2040e0"), entry("black", "#101010"), entry("red", "#e02020"), entry("redwrap", "#ff0030"), entry("green", "#20c040")];
    compare(names(WallpaperPicker.sorted(list, "hue")), "redwrap,red,green,blue,black,white,none");
  }

  function test_filtered_combines_query_family_and_sort() {
    const list = [entry("blue sea", "#2040e0", 1), entry("blue night", "#101010", 2), entry("deep blue sky", "#3050d0", 3), entry("red sky", "#e02020", 4)];
    compare(names(WallpaperPicker.filtered(list, "blue", "blue", "name")), "blue sea,deep blue sky");
    compare(names(WallpaperPicker.filtered(list, "sky", "", "date")), "red sky,deep blue sky");
    compare(names(WallpaperPicker.filtered(list, "", "black", "name")), "blue night");
    compare(WallpaperPicker.filtered(list, "nothing", "", "name").length, 0);
    compare(WallpaperPicker.filtered(null, "", "", "name").length, 0);
  }

  function test_keep_selection() {
    const list = [entry("a"), entry("b"), entry("c")];
    compare(WallpaperPicker.keepSelection(list, "/w/b.png", 0), 1);
    compare(WallpaperPicker.keepSelection(list, "/w/gone.png", 7), 2);
    compare(WallpaperPicker.keepSelection(list, "", 1), 1);
    compare(WallpaperPicker.keepSelection([], "/w/a.png", 1), -1);
  }

  function test_step_clamps() {
    compare(WallpaperPicker.step(0, -1, 5), 0);
    compare(WallpaperPicker.step(3, 1, 5), 4);
    compare(WallpaperPicker.step(4, 1, 5), 4);
    compare(WallpaperPicker.step(-1, 1, 5), 1);
    compare(WallpaperPicker.step(2, 10, 5), 4);
    compare(WallpaperPicker.step(0, 1, 0), -1);
  }

  function test_next_family_cycles_through_all_colors() {
    compare(WallpaperPicker.nextFamily("", 1), "red");
    compare(WallpaperPicker.nextFamily("red", -1), "");
    compare(WallpaperPicker.nextFamily("", -1), "white");
    compare(WallpaperPicker.nextFamily("white", 1), "");
    compare(WallpaperPicker.nextFamily("nonsense", 1), "red");
  }

  function test_next_sort_wraps() {
    compare(WallpaperPicker.nextSort("name"), "date");
    compare(WallpaperPicker.nextSort("hue"), "name");
    compare(WallpaperPicker.nextSort("name", -1), "hue");
    compare(WallpaperPicker.nextSort("bogus"), "date");
  }

  function test_backspace() {
    compare(WallpaperPicker.backspace("snow road", false), "snow roa");
    compare(WallpaperPicker.backspace("snow road", true), "snow");
    compare(WallpaperPicker.backspace("snow road  ", true), "snow");
    compare(WallpaperPicker.backspace("snow", true), "");
    compare(WallpaperPicker.backspace("", false), "");
  }

  function test_typable() {
    verify(WallpaperPicker.typable("a"));
    verify(WallpaperPicker.typable(" "));
    verify(WallpaperPicker.typable("é"));
    verify(!WallpaperPicker.typable(""));
    verify(!WallpaperPicker.typable("\t"));
    verify(!WallpaperPicker.typable("\r"));
    verify(!WallpaperPicker.typable("\x7f"));
    verify(!WallpaperPicker.typable("ab"));
    verify(!WallpaperPicker.typable(undefined));
  }

  function test_badge_and_title() {
    compare(WallpaperPicker.badge("png"), "PNG");
    compare(WallpaperPicker.badge("jpeg"), "JPG");
    compare(WallpaperPicker.badge(""), "");
    compare(WallpaperPicker.title(entry("snow road")), "snow road");
    compare(WallpaperPicker.title(null), "");
  }

  // Carousel geometry ----------------------------------------------------

  readonly property var geo: ({
                                "centerWidth": 300,
                                "stripWidth": 60,
                                "gap": 10,
                                "height": 400,
                                "centerHeight": 480,
                                "skew": 0.2,
                                "mirror": false,
                                "half": 3
                              })

  function test_offsets_pack_strips_beside_the_center() {
    compare(WallpaperPicker.offsetX(0, geo), 0);
    // Half the center card, the gap and half a strip
    compare(WallpaperPicker.offsetX(1, geo), 190);
    compare(WallpaperPicker.offsetX(-1, geo), -190);
    compare(WallpaperPicker.offsetX(2, geo), 260);
    compare(WallpaperPicker.offsetX(0.5, geo), 95);
  }

  function test_offsets_are_monotonic_while_scrolling() {
    let previous = -Infinity;
    for (let d = -4; d <= 4; d += 0.125) {
      const x = WallpaperPicker.offsetX(d, geo);
      verify(x > previous, "offset at " + d);
      previous = x;
    }
  }

  function test_card_shape() {
    const center = WallpaperPicker.card(0, geo);
    compare(center.width, 300);
    compare(center.height, 480);
    compare(center.focus, 1);
    compare(center.skew, 0);
    compare(center.opacity, 1);
    const strip = WallpaperPicker.card(2, geo);
    compare(strip.width, 60);
    compare(strip.height, 400);
    compare(strip.skew, 0.2);
    verify(strip.z < center.z);
    // Halfway: halfway sizes, half the lean
    const half = WallpaperPicker.card(-0.5, geo);
    compare(half.width, 180);
    compare(half.height, 440);
    compare(half.skew, 0.1);
  }

  function test_mirrored_strips_lean_away_from_the_center() {
    const g = Object.assign({}, geo, {
                              "mirror": true
                            });
    compare(WallpaperPicker.card(2, g).skew, 0.2);
    compare(WallpaperPicker.card(-2, g).skew, -0.2);
  }

  function test_outermost_strips_fade() {
    compare(WallpaperPicker.card(3, geo).opacity, 1);
    compare(WallpaperPicker.card(3.25, geo).opacity, 0.5);
    compare(WallpaperPicker.card(-4, geo).opacity, 0);
  }

  function test_visible_half() {
    // (1000 / 2 - 150 - 10 + 10) / 70 = 5
    compare(WallpaperPicker.visibleHalf(1000, geo), 5);
    compare(WallpaperPicker.visibleHalf(200, geo), 0);
  }

  function test_slots_cover_the_window_once() {
    const half = 3, size = WallpaperPicker.slotCount(half);
    compare(size, 9);
    for (const center of [0, 4, 4.4, 4.6, 20]) {
      const seen = [];
      for (let slot = 0; slot < size; slot++) {
        const index = WallpaperPicker.slotIndex(slot, center, half, 100);
        if (index >= 0) {
          verify(seen.indexOf(index) === -1, "duplicate " + index);
          seen.push(index);
        }
      }
      const c = Math.round(center);
      for (let i = Math.max(0, c - half); i <= c + half; i++)
        verify(seen.indexOf(i) !== -1, "center " + center + " misses " + i);
    }
  }

  function test_slots_keep_their_card_while_scrolling() {
    for (let slot = 0; slot < 9; slot++) {
      const before = WallpaperPicker.slotIndex(slot, 10, 3, 100);
      const after = WallpaperPicker.slotIndex(slot, 11, 3, 100);
      // Only the slot that falls off the left edge changes its card
      if (before !== 6)
        compare(after, before);
      else
        compare(after, 15);
    }
  }

  function test_slots_outside_the_list_are_empty() {
    compare(WallpaperPicker.slotIndex(0, 0, 3, 2), 0);
    let shown = 0;
    for (let slot = 0; slot < 9; slot++)
      shown += WallpaperPicker.slotIndex(slot, 0, 3, 2) >= 0 ? 1 : 0;
    compare(shown, 2);
  }

  // Time of day ---------------------------------------------------------

  // Folders and random picks --------------------------------------------

  function test_phase_eases_between_its_bounds() {
    compare(WallpaperPicker.phase(0.1, 0.2, 0.6), 0);
    compare(WallpaperPicker.phase(0.6, 0.2, 0.6), 1);
    compare(WallpaperPicker.phase(0.9, 0.2, 0.6), 1);
    verify(WallpaperPicker.phase(0.4, 0.2, 0.6) > 0.5, "ease-out is past half at the midpoint");
  }

  function test_pop_phase_overshoots_then_lands() {
    compare(WallpaperPicker.popPhase(0, 0, 1), 0);
    fuzzyCompare(WallpaperPicker.popPhase(1, 0, 1), 1, 1e-9);
    let peak = 0;
    for (let t = 0; t <= 1; t += 0.05)
      peak = Math.max(peak, WallpaperPicker.popPhase(t, 0, 1));
    verify(peak > 1, "overshoots");
  }

  function test_intro_shows_the_selected_card_first() {
    const center = WallpaperPicker.card(0, geo);
    const strip = WallpaperPicker.card(2, geo);
    const early = 0.15;
    verify(WallpaperPicker.introCard(center, 0, early, 3).opacity > 0, "selected card is appearing");
    compare(WallpaperPicker.introCard(strip, 2, early, 3).opacity, 0);
    compare(WallpaperPicker.introCard(strip, 2, early, 3).x, 0);
  }

  function test_intro_unfolds_nearest_strips_first() {
    const t = 0.45;
    const near = WallpaperPicker.introCard(WallpaperPicker.card(1, geo), 1, t, 3);
    const far = WallpaperPicker.introCard(WallpaperPicker.card(-3, geo), -3, t, 3);
    verify(near.x / WallpaperPicker.card(1, geo).x > far.x / WallpaperPicker.card(-3, geo).x);
    verify(far.x <= 0, "left strips slide out to the left");
  }

  function test_intro_done_is_the_plain_card() {
    const look = WallpaperPicker.card(-2.5, geo);
    const done = WallpaperPicker.introCard(look, -2.5, 1, 3);
    compare(done.x, look.x);
    compare(done.opacity, look.opacity);
    compare(done.skew, look.skew);
    compare(done.scale, 1);
  }

  function test_intro_bar_grows_then_items_pop_in_order() {
    compare(WallpaperPicker.introBar(0).opacity, 0);
    compare(WallpaperPicker.introBar(0).grow, 0);
    compare(WallpaperPicker.introBar(0).lift, 1);
    const end = WallpaperPicker.introBar(1);
    compare(end.opacity, 1);
    compare(end.grow, 1);
    compare(end.lift, 0);
    compare(WallpaperPicker.introItem(0.4, 0, 10), 0);
    verify(WallpaperPicker.introItem(0.6, 0, 10) > WallpaperPicker.introItem(0.6, 5, 10));
    for (let i = 0; i < 10; i++)
      fuzzyCompare(WallpaperPicker.introItem(1, i, 10), 1, 1e-9);
  }

  function test_file_url_escapes_special_characters() {
    compare(WallpaperPicker.fileUrl("/home/a/Wall/sky.png"), "file:///home/a/Wall/sky.png");
    compare(WallpaperPicker.fileUrl("/home/a/my wall #2?.jpg"), "file:///home/a/my%20wall%20%232%3F.jpg");
    compare(WallpaperPicker.fileUrl("/w/100%.png"), "file:///w/100%25.png");
    compare(WallpaperPicker.fileUrl("relative.png"), "");
    compare(WallpaperPicker.fileUrl(null), "");
  }

  function test_apply_updates() {
    const list = [entry("a"), entry("b")];
    const merged = WallpaperPicker.applyUpdates(list, [
                                                  {
                                                    "path": "/w/b.png",
                                                    "color": "#123456",
                                                    "thumb": "/t/b.jpg"
                                                  }
                                                ]);
    compare(merged[1].color, "#123456");
    compare(merged[1].thumb, "/t/b.jpg");
    compare(merged[1].name, "b");
    compare(list[1].color, null);
    verify(merged[0] === list[0]);
    verify(WallpaperPicker.applyUpdates(list, []) === list);
  }
}
