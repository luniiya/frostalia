import QtQuick
import QtTest
import "../Helpers/KdeConnect.js" as KdeConnect

TestCase {
  name: "KdeConnect"

  function device(id, reachable, paired, extra) {
    return Object.assign({
                           id: id,
                           name: id,
                           type: "phone",
                           reachable: reachable,
                           paired: paired,
                           plugins: [],
                           supportedPlugins: []
                         }, extra || {});
  }

  function message(uid, thread, date, sent, body, read) {
    return {
      uid: uid,
      thread: thread,
      date: date,
      sent: sent,
      body: body || ("m" + uid),
      read: read === undefined ? true : read,
      addresses: ["+15550100"],
      attachments: []
    };
  }

  // -- devices --------------------------------------------------------------

  function test_active_device_data() {
    const phone = device("phone", true, true);
    const tablet = device("tablet", true, true);
    const offline = device("old", false, true);
    const stranger = device("stranger", true, false);
    return [
          {
            tag: "only reachable device wins",
            devices: [offline, phone],
            preferred: "",
            expected: "phone"
          },
          {
            tag: "remembered reachable device",
            devices: [phone, tablet],
            preferred: "tablet",
            expected: "tablet"
          },
          {
            tag: "remembered but offline falls back to reachable",
            devices: [phone, offline],
            preferred: "old",
            expected: "phone"
          },
          {
            tag: "nothing reachable keeps remembered",
            devices: [device("a", false, true), offline],
            preferred: "old",
            expected: "old"
          },
          {
            tag: "unpaired devices are ignored",
            devices: [stranger],
            preferred: "stranger",
            expected: ""
          },
          {
            tag: "no devices",
            devices: [],
            preferred: "",
            expected: ""
          }
        ];
  }

  function test_active_device(data) {
    const active = KdeConnect.activeDevice(data.devices, data.preferred);
    compare(active ? active.id : "", data.expected);
  }

  function test_device_icon_and_battery() {
    const phone = device("p", true, true, {
                           battery: {
                             charge: 77,
                             charging: true
                           }
                         });
    compare(KdeConnect.deviceIcon(phone), "device-mobile-charging");
    compare(KdeConnect.batteryText(phone), "77%");
    phone.battery.charging = false;
    compare(KdeConnect.deviceIcon(phone), "device-mobile");
    const offline = device("o", false, true, {
                             battery: {
                               charge: 50,
                               charging: false
                             }
                           });
    compare(KdeConnect.deviceIcon(offline), "device-mobile-off");
    compare(KdeConnect.batteryText(offline), "", "stale battery of an offline phone is hidden");
    compare(KdeConnect.batteryText(device("n", true, true)), "");
    compare(KdeConnect.deviceIcon(device("t", true, true, {
                                           type: "tablet"
                                         })), "device-tablet");
  }

  function test_signal_icon() {
    compare(KdeConnect.signalIcon(null), "antenna-bars-off");
    compare(KdeConnect.signalIcon({
                                    strength: -1
                                  }), "antenna-bars-off");
    compare(KdeConnect.signalIcon({
                                    strength: 0
                                  }), "antenna-bars-1");
    compare(KdeConnect.signalIcon({
                                    strength: 4
                                  }), "antenna-bars-5");
    compare(KdeConnect.signalIcon({
                                    strength: 9
                                  }), "antenna-bars-5");
  }

  function test_features_follow_loaded_plugins() {
    const phone = device("p", true, true, {
                           plugins: ["kdeconnect_sms", "kdeconnect_mousepad", "kdeconnect_remotekeyboard", "kdeconnect_findmyphone", "kdeconnect_share"]
                         });
    compare(KdeConnect.availableFeatures(phone).map(f => f.id), ["messages", "remote"], "remote keyboard alone offers the remote page");
    compare(KdeConnect.availableActions(phone).map(a => a.id), ["ring", "share"]);
    phone.reachable = false;
    compare(KdeConnect.availableFeatures(phone), []);
    compare(KdeConnect.availableActions(phone), []);
  }

  function test_plugin_entries() {
    const phone = device("p", true, true, {
                           plugins: ["kdeconnect_ping"],
                           supportedPlugins: ["kdeconnect_share", "kdeconnect_ping", "kdeconnect_connectivity_report"]
                         });
    const entries = KdeConnect.pluginEntries(phone);
    compare(entries.map(e => e.id), ["kdeconnect_connectivity_report", "kdeconnect_ping", "kdeconnect_share"]);
    compare(entries.map(e => e.enabled), [false, true, false]);
    compare(entries[0].name, "Connectivity report");
    compare(KdeConnect.pluginEntries(null), []);
  }

  // -- contacts -------------------------------------------------------------

  function test_normalize_number_data() {
    return [
          {
            tag: "international",
            input: "+33 6 12 34 56 78",
            expected: "612345678"
          },
          {
            tag: "national",
            input: "06 12 34 56 78",
            expected: "612345678"
          },
          {
            tag: "short code",
            input: "36179",
            expected: "36179"
          },
          {
            tag: "empty",
            input: "",
            expected: ""
          }
        ];
  }

  function test_normalize_number(data) {
    compare(KdeConnect.normalizeNumber(data.input), data.expected);
  }

  function test_contact_matching() {
    const contacts = [
            {
              name: "Alex",
              numbers: ["+33 6 12 34 56 78"],
              photo: ""
            },
            {
              name: "Bank",
              numbers: ["36179"],
              photo: ""
            }
          ];
    compare(KdeConnect.displayName("0612345678", contacts), "Alex");
    compare(KdeConnect.displayName("36179", contacts), "Bank");
    compare(KdeConnect.displayName("+1555", contacts), "+1555");
    compare(KdeConnect.contactFor("", contacts), null);
    compare(KdeConnect.threadTitle(["0612345678", "+1555"], contacts), "Alex, +1555");
  }

  function test_initials_data() {
    return [
          {
            tag: "two words",
            input: "jane doe",
            expected: "JD"
          },
          {
            tag: "one word",
            input: "Alex",
            expected: "A"
          },
          {
            tag: "number",
            input: "+33 6 12",
            expected: "#"
          },
          {
            tag: "punctuation ignored",
            input: "Mom ❤",
            expected: "M"
          },
          {
            tag: "empty",
            input: "  ",
            expected: ""
          }
        ];
  }

  function test_initials(data) {
    compare(KdeConnect.initials(data.input), data.expected);
  }

  // -- threads --------------------------------------------------------------

  function test_thread_list_updates() {
    let threads = KdeConnect.sortThreads([message(1, 1, 100, false), message(2, 2, 300, true)]);
    compare(threads.map(t => t.thread), [2, 1]);
    threads = KdeConnect.upsertThread(threads, message(3, 1, 400, false, "new", false));
    compare(threads.map(t => t.thread), [1, 2], "updated thread moves to the top");
    compare(threads[0].body, "new");
    compare(KdeConnect.unreadCount(threads), 1);
    threads = KdeConnect.upsertThread(threads, message(4, 1, 50, false, "older"));
    compare(threads[0].body, "new", "an older message does not replace the preview");
    threads = KdeConnect.removeThread(threads, 1);
    compare(threads.map(t => t.thread), [2]);
  }

  function test_merge_message_dedupes_and_sorts() {
    let list = [message(1, 7, 100, false), message(2, 7, 300, true)];
    list = KdeConnect.mergeMessage(list, message(3, 7, 200, false));
    compare(list.map(m => m.uid), [1, 3, 2]);
    list = KdeConnect.mergeMessage(list, message(3, 7, 200, false, "edited"));
    compare(list.length, 3);
    compare(list[1].body, "edited");
  }

  function test_sent_message_replaces_pending_bubble() {
    let list = [message(1, 7, 100, false)];
    list = KdeConnect.mergeMessage(list, KdeConnect.pendingMessage(7, "on my way", 500, 0));
    compare(list[1].pending, true);
    compare(list[1].uid, -1);
    list = KdeConnect.mergeMessage(list, message(9, 7, 510, true, "on my way"));
    compare(list.map(m => m.uid), [1, 9]);
    compare(list[1].pending, undefined);
  }

  function test_bubble_groups() {
    const min = 60 * 1000;
    const base = new Date(2026, 9, 19, 12, 0).getTime();
    const list = [message(1, 1, base, false), message(2, 1, base + min, false), message(3, 1, base + 2 * min, true), message(4, 1, base + 20 * min, true), message(5, 1, base + 24 * 3600 * 1000, true)];
    const b = KdeConnect.bubbles(list);
    compare(b.map(x => x.first), [true, false, true, true, true]);
    compare(b.map(x => x.last), [false, true, true, true, true]);
    compare(b.map(x => x.daySeparator), [true, false, false, false, true]);
    compare(KdeConnect.bubbles([]), []);
  }

  function test_time_kind() {
    const now = new Date(2026, 9, 19, 15, 0).getTime();
    compare(KdeConnect.timeKind(new Date(2026, 9, 19, 1, 0).getTime(), now), "time");
    compare(KdeConnect.timeKind(new Date(2026, 9, 17, 23, 0).getTime(), now), "weekday");
    compare(KdeConnect.timeKind(new Date(2026, 9, 1, 12, 0).getTime(), now), "date");
  }

  function test_attachment_images() {
    const m = message(1, 1, 1, false);
    m.attachments = [
          {
            mime: "image/jpeg",
            thumbnail: "data:image/jpeg;base64,AA"
          },
          {
            mime: "video/mp4",
            thumbnail: "data:video/mp4;base64,AA"
          },
          {
            mime: "image/png",
            thumbnail: ""
          }
        ];
    compare(KdeConnect.attachmentImages(m).length, 1);
    compare(KdeConnect.attachmentImages(null), []);
  }

  // -- media ----------------------------------------------------------------

  function test_format_duration_data() {
    return [
          {
            tag: "zero",
            ms: 0,
            expected: "0:00"
          },
          {
            tag: "minutes",
            ms: 185000,
            expected: "3:05"
          },
          {
            tag: "hours",
            ms: 3725000,
            expected: "1:02:05"
          },
          {
            tag: "negative",
            ms: -5,
            expected: "0:00"
          }
        ];
  }

  function test_format_duration(data) {
    compare(KdeConnect.formatDuration(data.ms), data.expected);
  }

  function test_progress() {
    compare(KdeConnect.progress(null), 0);
    compare(KdeConnect.progress({
                                  position: 50,
                                  length: 200
                                }), 0.25);
    compare(KdeConnect.progress({
                                  position: 500,
                                  length: 200
                                }), 1);
    compare(KdeConnect.progress({
                                  position: 5,
                                  length: 0
                                }), 0);
  }

  // -- remote input ---------------------------------------------------------

  function test_touchpad_carries_fractions() {
    let step = KdeConnect.touchpadStep(null, 1, -1, 0.4);
    compare([step.dx, step.dy], [0, 0]);
    step = KdeConnect.touchpadStep(step.carry, 1, -1, 0.4);
    compare([step.dx, step.dy], [0, 0]);
    step = KdeConnect.touchpadStep(step.carry, 1, -1, 0.4);
    compare([step.dx, step.dy], [1, -1], "three slow moves add up to one pixel");
    step = KdeConnect.touchpadStep(null, 10, 5, 2);
    compare([step.dx, step.dy], [20, 10]);
  }

  function test_key_press_data() {
    return [
          {
            tag: "letter",
            key: Qt.Key_A,
            text: "a",
            modifiers: 0,
            expected: {
              key: "a",
              special: 0,
              shift: false,
              ctrl: false,
              alt: false
            }
          },
          {
            tag: "shifted",
            key: Qt.Key_A,
            text: "A",
            modifiers: Qt.ShiftModifier,
            expected: {
              key: "A",
              special: 0,
              shift: true,
              ctrl: false,
              alt: false
            }
          },
          {
            tag: "ctrl+c",
            key: Qt.Key_C,
            text: "\u0003",
            modifiers: Qt.ControlModifier,
            expected: {
              key: "c",
              special: 0,
              shift: false,
              ctrl: true,
              alt: false
            }
          },
          {
            tag: "backspace",
            key: Qt.Key_Backspace,
            text: "\b",
            modifiers: 0,
            expected: {
              key: "",
              special: 1,
              shift: false,
              ctrl: false,
              alt: false
            }
          },
          {
            tag: "enter",
            key: Qt.Key_Return,
            text: "\r",
            modifiers: 0,
            expected: {
              key: "",
              special: 12,
              shift: false,
              ctrl: false,
              alt: false
            }
          },
          {
            tag: "f5",
            key: Qt.Key_F5,
            text: "",
            modifiers: 0,
            expected: {
              key: "",
              special: 25,
              shift: false,
              ctrl: false,
              alt: false
            }
          }
        ];
  }

  function test_key_press(data) {
    compare(KdeConnect.keyPress(data.key, data.text, data.modifiers), data.expected);
  }

  function test_key_press_ignores_bare_modifiers() {
    compare(KdeConnect.keyPress(Qt.Key_Shift, "", Qt.ShiftModifier), null);
  }

  // -- share and commands ---------------------------------------------------

  function test_share_urls() {
    compare(KdeConnect.shareUrls(["/home/me/My File.pdf", "https://example.org/x", "file:///tmp/a", ""]), ["file:///home/me/My%20File.pdf", "https://example.org/x", "file:///tmp/a"]);
  }

  function test_clean_commands() {
    compare(KdeConnect.cleanCommands([
                                       {
                                         id: "a",
                                         name: " Lock ",
                                         command: "hyprlock"
                                       },
                                       {
                                         name: "",
                                         command: "x"
                                       },
                                       {
                                         name: "Empty",
                                         command: " "
                                       }
                                     ]), [
              {
                id: "a",
                name: "Lock",
                command: "hyprlock"
              }
            ]);
  }

  // -- navigation -----------------------------------------------------------

  function test_page_stack() {
    let stack = KdeConnect.popPage(null);
    compare(stack.map(p => p.page), ["home"]);
    stack = KdeConnect.pushPage(stack, "messages");
    stack = KdeConnect.pushPage(stack, "thread", {
                                  thread: 7
                                });
    compare(stack.map(p => p.page), ["home", "messages", "thread"]);
    compare(stack[2].props.thread, 7);
    stack = KdeConnect.popPage(stack);
    compare(stack.map(p => p.page), ["home", "messages"]);
    compare(KdeConnect.popPage([
                                 {
                                   page: "home",
                                   props: {}
                                 }
                               ]).length, 1, "home cannot be popped");
  }

  function test_offline_drops_feature_pages() {
    const stack = [
            {
              page: "home",
              props: {}
            },
            {
              page: "device",
              props: {}
            },
            {
              page: "messages",
              props: {}
            }
          ];
    compare(KdeConnect.reachablePages(stack, true), stack);
    compare(KdeConnect.reachablePages(stack, false).map(p => p.page), ["home", "device"]);
    compare(KdeConnect.reachablePages([], false).map(p => p.page), ["home"]);
  }

  function test_widget_visibility() {
    const online = device("p", true, true);
    const offline = device("p", false, true);
    verify(KdeConnect.widgetVisible(true, online, true));
    verify(!KdeConnect.widgetVisible(true, offline, true));
    verify(KdeConnect.widgetVisible(true, offline, false));
    verify(KdeConnect.widgetVisible(true, null, false));
    verify(!KdeConnect.widgetVisible(false, online, false), "disabled integration hides the widget");
  }

  function test_unreadSuffix() {
    compare(KdeConnect.unreadSuffix(34, false), "", "hidden by default");
    compare(KdeConnect.unreadSuffix(34, true), " · 34");
    compare(KdeConnect.unreadSuffix(0, true), "");
  }
}
