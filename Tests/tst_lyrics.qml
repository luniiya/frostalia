import QtQuick
import QtTest
import "../Helpers/Lyrics.js" as Lyrics

TestCase {
  name: "Lyrics"

  function near(actual, expected, message) {
    fuzzyCompare(actual, expected, 0.001, message);
  }

  // ===== LRC =====

  function test_lrcTime_data() {
    return [
          {
            tag: "centiseconds",
            stamp: "01:02.50",
            seconds: 62.5
          },
          {
            tag: "milliseconds",
            stamp: "00:03.250",
            seconds: 3.25
          },
          {
            tag: "no fraction",
            stamp: "2:05",
            seconds: 125
          },
          {
            tag: "colon fraction",
            stamp: "00:01:50",
            seconds: 1.5
          }
        ];
  }

  function test_lrcTime(data) {
    near(Lyrics.lrcTime(data.stamp), data.seconds);
  }

  function test_lrcTime_rejects_tags() {
    verify(isNaN(Lyrics.lrcTime("ar:XG")));
  }

  function test_parseLrc_sorts_fills_ends_and_skips_tags() {
    const lines = Lyrics.parseLrc("[ar:XG]\n[ti:Something]\n[00:05.00]second\n[00:01.00]first  line\n\nnot a line");
    compare(lines.length, 2);
    compare(lines[0].text, "first line");
    near(lines[0].start, 1);
    near(lines[0].end, 5);
    near(lines[1].end, 10);
    compare(lines[0].words.length, 0);
  }

  function test_parseLrc_repeats_lines_with_several_stamps() {
    const lines = Lyrics.parseLrc("[00:01.00][00:09.00]chorus\n[00:05.00]verse");
    compare(lines.map(l => l.text).join("|"), "chorus|verse|chorus");
    near(lines[2].start, 9);
  }

  function test_parseLrc_offset_moves_lines_earlier() {
    const lines = Lyrics.parseLrc("[offset:+500]\n[00:02.00]hi");
    near(lines[0].start, 1.5);
  }

  function test_parseLrc_enhanced_word_timing() {
    const lines = Lyrics.parseLrc("[00:01.00]<00:01.00>Some<00:01.40>thing <00:02.00>right<00:02.60>");
    const words = lines[0].words;
    compare(lines[0].text, "Something right");
    compare(words.length, 2);
    compare(words[0].text, "Something");
    compare(words[0].parts.length, 2);
    near(words[0].start, 1);
    near(words[0].end, 2);
    compare(words[1].text, "right");
    near(words[1].end, 2.6);
  }

  // ===== Rufin =====

  function rufinPayload() {
    // "Something ain't right": two cues for "Something", one each for the rest;
    // a background voice that must be left out
    return {
      "state": "ready",
      "id": 7,
      "document": {
        "role": "Original",
        "offset_millis": 0,
        "agents": [
          {
            "id": "v1",
            "role": "Main"
          },
          {
            "id": "bg",
            "role": "Background"
          }
        ],
        "lines": [
          {
            "text": "Something ain't right",
            "start_millis": 1000,
            "end_millis": 3000,
            "cue_lines": [
              {
                "text": "(ooh)",
                "agent_id": "bg",
                "cues": [
                  {
                    "text": "ooh",
                    "start_millis": 1000,
                    "byte_start": 0,
                    "byte_end_exclusive": 3
                  }
                ]
              },
              {
                "text": "Something ain't right",
                "agent_id": "v1",
                "cues": [
                  {
                    "text": "Some",
                    "start_millis": 1000,
                    "end_millis": 1300,
                    "byte_start": 0,
                    "byte_end_exclusive": 4
                  },
                  {
                    "text": "thing",
                    "start_millis": 1300,
                    "end_millis": 1700,
                    "byte_start": 4,
                    "byte_end_exclusive": 9
                  },
                  {
                    "text": "ain't",
                    "start_millis": 1800,
                    "end_millis": 2200,
                    "byte_start": 10,
                    "byte_end_exclusive": 15
                  },
                  {
                    "text": "right",
                    "start_millis": 2300,
                    "end_millis": 2900,
                    "byte_start": 16,
                    "byte_end_exclusive": 21
                  }
                ]
              }
            ]
          },
          {
            "text": "You been acting funny lately",
            "start_millis": 3200
          }
        ]
      }
    };
  }

  function test_fromRufin_groups_cues_into_words() {
    const out = Lyrics.fromRufin(rufinPayload());
    compare(out.state, "ready");
    compare(out.id, 7);
    compare(out.lines.length, 2);
    const words = out.lines[0].words;
    compare(words.map(w => w.text).join("|"), "Something|ain't|right");
    compare(words[0].parts.length, 2);
    near(words[0].start, 1);
    near(words[0].end, 1.7);
    near(out.lines[0].end, 3);
  }

  function test_fromRufin_line_without_cues_has_no_words() {
    const out = Lyrics.fromRufin(rufinPayload());
    compare(out.lines[1].words.length, 0);
    near(out.lines[1].start, 3.2);
    near(out.lines[1].end, 8.2);
  }

  function test_fromRufin_multibyte_text_splits_on_spaces() {
    // "愛 して": the space is between byte 3 and byte 4
    const payload = {
      "state": "ready",
      "document": {
        "lines": [
          {
            "text": "愛 して",
            "start_millis": 0,
            "cue_lines": [
              {
                "cues": [
                  {
                    "text": "愛",
                    "start_millis": 0,
                    "end_millis": 400,
                    "byte_start": 0,
                    "byte_end_exclusive": 3
                  },
                  {
                    "text": "し",
                    "start_millis": 500,
                    "end_millis": 700,
                    "byte_start": 4,
                    "byte_end_exclusive": 7
                  },
                  {
                    "text": "て",
                    "start_millis": 700,
                    "end_millis": 900,
                    "byte_start": 7,
                    "byte_end_exclusive": 10
                  }
                ]
              }
            ]
          }
        ]
      }
    };
    const words = Lyrics.fromRufin(payload).lines[0].words;
    compare(words.map(w => w.text).join("|"), "愛|して");
  }

  function test_fromRufin_states_data() {
    return [
          {
            tag: "loading",
            payload: {
              "state": "loading",
              "id": 3
            },
            state: "loading"
          },
          {
            tag: "instrumental",
            payload: {
              "state": "instrumental"
            },
            state: "instrumental"
          },
          {
            tag: "empty",
            payload: {
              "state": "empty"
            },
            state: "empty"
          },
          {
            tag: "ready without lines",
            payload: {
              "state": "ready",
              "document": {
                "lines": []
              }
            },
            state: "empty"
          },
          {
            tag: "garbage",
            payload: null,
            state: "empty"
          }
        ];
  }

  function test_fromRufin_states(data) {
    compare(Lyrics.fromRufin(data.payload).state, data.state);
  }

  function test_isRufin() {
    verify(Lyrics.isRufin("Rufin", ""));
    verify(Lyrics.isRufin("", "io.github.screwys.Rufin"));
    verify(!Lyrics.isRufin("Spotify", "spotify"));
  }

  function test_rufinEndpoint() {
    const on = Lyrics.rufinEndpoint('{"web_controller":{"enabled":true,"address":"127.0.0.1","port":1718}}');
    verify(on.enabled);
    compare(on.url, "http://127.0.0.1:1718");
    compare(Lyrics.rufinEndpoint('{"web_controller":{"enabled":true,"address":"0.0.0.0","port":1717}}').url, "http://127.0.0.1:1717");
    compare(Lyrics.rufinEndpoint('{"web_controller":{"enabled":true,"address":"::1","port":1717}}').url, "http://[::1]:1717");
    verify(!Lyrics.rufinEndpoint('{"web_controller":{"enabled":false}}').enabled);
    verify(!Lyrics.rufinEndpoint("not json").enabled);
  }

  function test_rufinToken() {
    // base64 of "ab12"
    compare(Lyrics.rufinToken('{"format":"config-base64","secrets":{"web-controller:token":"YWIxMg=="}}'), "ab12");
    compare(Lyrics.rufinToken('{"format":"config-base64","secrets":{"provider-token:x":"YWIxMg=="}}'), "");
    compare(Lyrics.rufinToken("{"), "");
  }

  function test_eventData() {
    compare(Lyrics.eventData('data: {"state":"loading"}').state, "loading");
    compare(Lyrics.eventData("event: lyrics"), null);
    compare(Lyrics.eventData("data: {broken"), null);
  }

  // ===== LRCLIB =====

  function test_lrclib_urls() {
    compare(Lyrics.lrclibGetUrl("Idol", "YOASOBI", "", 213.4), "https://lrclib.net/api/get?track_name=Idol&artist_name=YOASOBI&duration=213");
    compare(Lyrics.lrclibSearchUrl("a b", "c&d"), "https://lrclib.net/api/search?track_name=a%20b&artist_name=c%26d");
  }

  function test_lrclibSettled_retries_network_errors() {
    compare(Lyrics.lrclibSettled(200), true);
    compare(Lyrics.lrclibSettled(404), true);
    compare(Lyrics.lrclibSettled(0), false);
    compare(Lyrics.lrclibSettled(502), false);
  }

  function test_pickLrclib_closest_synced_result() {
    const results = [
            {
              "duration": 200,
              "syncedLyrics": "[00:01.00]far"
            },
            {
              "duration": 211,
              "syncedLyrics": null
            },
            {
              "duration": 212,
              "syncedLyrics": "[00:01.00]close"
            }
          ];
    compare(Lyrics.pickLrclib(results, 213).duration, 212);
    compare(Lyrics.pickLrclib(results, 300), null);
  }

  function test_parseLrc_blank_lines_end_the_line_before_and_go() {
    const lines = Lyrics.parseLrc("[00:01.00]♪\n[00:05.00]hello\n[00:08.00]\n[00:20.00]again");
    compare(lines.length, 2);
    compare(lines[0].text, "hello");
    near(lines[0].end, 8);
    // The intro and the break are gaps, so the dots count them down
    verify(Lyrics.waiting(lines, 2, 3).show);
    verify(Lyrics.waiting(lines, 12, 6).show);
  }

  function test_isBlank() {
    verify(Lyrics.isBlank(""));
    verify(Lyrics.isBlank(" ♪ ♫ "));
    verify(Lyrics.isBlank("..."));
    verify(!Lyrics.isBlank("la"));
  }

  function test_lookupTitle_drops_featured_artists() {
    compare(Lyrics.lookupTitle("Switchblade (feat. Ty Dolla $ign)"), "Switchblade");
    compare(Lyrics.lookupTitle("Song [ft. X]"), "Song");
    compare(Lyrics.lookupTitle("Song feat. X"), "Song");
    compare(Lyrics.lookupTitle("Call of Silence（Remix）"), "Call of Silence（Remix）");
  }

  function test_firstArtist() {
    compare(Lyrics.firstArtist("aespa, Ty Dolla $ign"), "aespa");
    compare(Lyrics.firstArtist("A & B"), "A");
    compare(Lyrics.firstArtist("Clear Sky"), "Clear Sky");
  }

  function test_lrclibSearchUrls_fall_back_to_simpler_searches() {
    const urls = Lyrics.lrclibSearchUrls("Switchblade (feat. Ty Dolla $ign)", "aespa, Ty Dolla $ign");
    compare(urls.length, 3);
    compare(urls[1], "https://lrclib.net/api/search?track_name=Switchblade&artist_name=aespa");
    compare(urls[2], "https://lrclib.net/api/search?q=Switchblade%20aespa");
    // Nothing to simplify: by fields, then free text
    compare(Lyrics.lrclibSearchUrls("Idol", "YOASOBI").length, 2);
  }

  function test_cleanTitle() {
    compare(Lyrics.cleanTitle("Idol (Official Music Video)"), "Idol");
    compare(Lyrics.cleanTitle("Killer neuron【MV】"), "Killer neuron");
    compare(Lyrics.cleanTitle("Song (feat. X)"), "Song (feat. X)");
  }

  // ===== Timing =====

  function lines3() {
    return [
          {
            "start": 1,
            "end": 3,
            "text": "a",
            "words": []
          },
          {
            "start": 3,
            "end": 6,
            "text": "b",
            "words": []
          },
          {
            "start": 6,
            "end": 9,
            "text": "c",
            "words": []
          }
        ];
  }

  function test_lineIndexAt() {
    const lines = lines3();
    compare(Lyrics.lineIndexAt(lines, 0.5), -1);
    compare(Lyrics.lineIndexAt(lines, 1), 0);
    compare(Lyrics.lineIndexAt(lines, 5.9), 1);
    compare(Lyrics.lineIndexAt(lines, 100), 2);
    compare(Lyrics.lineIndexAt([], 1), -1);
  }

  function test_cursor_glides_into_the_next_line() {
    const lines = lines3();
    near(Lyrics.cursor(lines, 4, 0.4), 1);
    near(Lyrics.cursor(lines, 5.8, 0.4), 1.5);
    near(Lyrics.cursor(lines, 6, 0.4), 2);
    near(Lyrics.cursor(lines, 50, 0.4), 2);
    near(Lyrics.cursor(lines, 0.8, 0.4), -0.5);
  }

  function test_tokens_share_the_line_by_length() {
    const words = Lyrics.tokens({
                                  "start": 0,
                                  "end": 2,
                                  "text": "ab cdef",
                                  "words": []
                                });
    compare(words.length, 2);
    near(words[0].start, 0);
    near(words[0].end, words[1].start);
    // 3 : 5 by length (plus one for the space)
    near((words[0].end - words[0].start) / (words[1].end - words[1].start), 3 / 5);
    verify(words[1].end <= 2);
  }

  function test_tokens_keep_source_words() {
    const words = [
            {
              "text": "x",
              "start": 1,
              "end": 2,
              "parts": []
            }
          ];
    const kept = Lyrics.tokens({
                                 "start": 0,
                                 "end": 5,
                                 "text": "x",
                                 "words": words
                               });
    compare(kept.length, 1);
    compare(kept[0].text, "x");
    compare(kept[0].start, 1);
    compare(kept[0].end, 2);
    compare(kept[0].adlib, false);
    compare(Lyrics.tokens({
                            "start": 0,
                            "end": 5,
                            "text": "  ",
                            "words": []
                          }).length, 0);
  }

  function test_sung() {
    const word = {
      "text": "ab",
      "start": 1,
      "end": 2,
      "parts": []
    };
    near(Lyrics.sung(word, 0.5), 0);
    near(Lyrics.sung(word, 1.5), 0.5);
    near(Lyrics.sung(word, 3), 1);
    // Syllables fill in turn, weighted by length: "Some" (4) then "thing" (5)
    const syllables = {
      "text": "Something",
      "start": 1,
      "end": 2,
      "parts": [
        {
          "text": "Some",
          "start": 1,
          "end": 1.2
        },
        {
          "text": "thing",
          "start": 1.5,
          "end": 2
        }
      ]
    };
    near(Lyrics.sung(syllables, 1.3), 4 / 9);
    near(Lyrics.sung(syllables, 1.75), (4 + 2.5) / 9);
  }

  function test_pose_blends_between_rows() {
    const on = Lyrics.pose(0);
    near(on.scale, 1);
    near(on.opacity, 1);
    near(on.y, 0);
    const next = Lyrics.pose(1);
    near(next.scale, 0.66);
    verify(next.y > 0);
    const before = Lyrics.pose(-1);
    verify(before.y < 0);
    verify(before.opacity < next.opacity);
    verify(before.rotation > 0 && next.rotation < 0);
    const half = Lyrics.pose(0.5);
    verify(half.scale < 1 && half.scale > 0.66);
    near(Lyrics.pose(2).opacity, 0);
    near(Lyrics.pose(-3).opacity, 0);
  }

  function test_calmPose_is_even_and_untilted() {
    near(Lyrics.calmPose(0).scale, 1);
    near(Lyrics.calmPose(1).y, -Lyrics.calmPose(-1).y);
    near(Lyrics.calmPose(-0.6).rotation, 0);
    near(Lyrics.calmPose(0.4).rotation, 0);
    near(Lyrics.calmPose(3).opacity, 0);
  }

  function test_fit() {
    near(Lyrics.fit(300, 600), 1);
    near(Lyrics.fit(800, 600), 0.75);
    near(Lyrics.fit(5000, 600), 0.45);
  }

  function test_wave_runs_along_the_line() {
    near(Lyrics.wave(1, 0, 3), 0);
    near(Lyrics.wave(-0.5, 0, 3), 0);
    // Midway the first word is further along than the last
    verify(Lyrics.wave(0.7, 0, 3) > Lyrics.wave(0.7, 2, 3));
    near(Lyrics.wave(0, 1, 3), 0);
  }

  function test_marker_hops_word_to_word() {
    const words = [
            {
              "start": 1
            },
            {
              "start": 2
            },
            {
              "start": 4
            }
          ];
    compare(Lyrics.wordAt(words, 0.5), -1);
    compare(Lyrics.wordAt(words, 2.5), 1);
    near(Lyrics.hop(words, 1, 3), 0.5);
    near(Lyrics.hop(words, 2, 5), 0);
    near(Lyrics.arch(0.5), 1);
    near(Lyrics.arch(0), 0);
    near(Lyrics.hit(words[0], 1), 1);
    near(Lyrics.hit(words[0], 1.5), 0);
    near(Lyrics.hit(words[0], 0.5), 0);
  }

  function test_adlibs_are_marked_and_skipped_by_the_marker() {
    const words = Lyrics.tokens({
                                  "start": 0,
                                  "end": 4,
                                  "text": "hold me (ooh ooh) tight"
                                });
    compare(words.map(w => w.adlib), [false, false, true, true, false]);
    compare(Lyrics.mainIndexes(words), [0, 1, 4]);
    compare(Lyrics.mainIndexes(Lyrics.tokens({
                                               "start": 0,
                                               "end": 1,
                                               "text": "(yeah)"
                                             })), [0]);
  }

  function test_waiting() {
    const lines = [
            {
              "start": 10,
              "end": 12,
              "text": "a",
              "words": []
            },
            {
              "start": 30,
              "end": 32,
              "text": "b",
              "words": []
            }
          ];
    const intro = Lyrics.waiting(lines, 5, 4);
    verify(intro.show);
    near(intro.progress, 0.5);
    verify(!Lyrics.waiting(lines, 11, 4).show);
    verify(Lyrics.waiting(lines, 21, 4).show);
    verify(!Lyrics.waiting(lines, 40, 4).show);
    verify(!Lyrics.waiting([], 1, 4).show);
  }

  function test_busctlPosition() {
    near(Lyrics.busctlPosition("x 97702000\n"), 97.702);
    near(Lyrics.busctlPosition("x 0"), 0);
    compare(Lyrics.busctlPosition(""), -1);
    compare(Lyrics.busctlPosition("Failed to get property"), -1);
  }

  function test_trackLine() {
    compare(Lyrics.trackLine("Song", "Artist"), "Song · Artist");
    compare(Lyrics.trackLine("Song", ""), "Song");
  }

  function test_trackTag() {
    compare(Lyrics.trackTag("Something Ain't Right (Official MV)", "XG"), "SOMETHING AIN'T RIGHT - XG");
    compare(Lyrics.trackTag("Solo", ""), "SOLO");
  }
}
