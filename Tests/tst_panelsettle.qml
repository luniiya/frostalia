import QtQuick
import QtTest
import "../Helpers/PanelSettle.js" as PanelSettle

TestCase {
  name: "PanelSettle"

  function panel(fields) {
    return Object.assign({
                           "objectName": "controlCenterPanel-eDP-1",
                           "isPanelVisible": true,
                           "isClosing": false,
                           "sizeAnimationComplete": true,
                           "opacity": 1
                         }, fields);
  }

  function test_phase_data() {
    return [
          {
            tag: "missing",
            panel: null,
            expected: "closed"
          },
          {
            tag: "hidden",
            panel: panel({
                           "isPanelVisible": false
                         }),
            expected: "closed"
          },
          {
            tag: "growing",
            panel: panel({
                           "sizeAnimationComplete": false
                         }),
            expected: "opening"
          },
          {
            tag: "fading in",
            panel: panel({
                           "opacity": 0.4
                         }),
            expected: "opening"
          },
          {
            tag: "closing",
            panel: panel({
                           "isClosing": true
                         }),
            expected: "closing"
          },
          {
            tag: "open",
            panel: panel({}),
            expected: "open"
          }
        ];
  }

  function test_phase(data) {
    compare(PanelSettle.phase(data.panel), data.expected);
  }

  function test_panelName() {
    compare(PanelSettle.panelName("controlCenterPanel-eDP-1"), "controlCenterPanel");
    compare(PanelSettle.panelName("launcherPanel"), "launcherPanel");
    compare(PanelSettle.panelName(undefined), "");
  }

  function test_state_data() {
    return [
          {
            tag: "nothing",
            shell: {},
            expected: "closed"
          },
          {
            tag: "missing",
            shell: undefined,
            expected: "closed"
          },
          {
            tag: "panel open",
            shell: {
              "opened": panel({})
            },
            expected: "open:controlCenterPanel"
          },
          {
            tag: "panel fading in",
            shell: {
              "opened": panel({
                                "opacity": 0.5
                              })
            },
            expected: "busy"
          },
          {
            tag: "panel still closing behind a new one",
            shell: {
              "opened": panel({}),
              "closing": panel({
                                 "isClosing": true
                               })
            },
            expected: "busy"
          },
          {
            tag: "settings window",
            shell: {
              "settingsWindowOpen": true
            },
            expected: "open:settingsWindow"
          },
          {
            tag: "overlay launcher",
            shell: {
              "overlayLauncherOpen": true
            },
            expected: "open:launcherOverlay"
          },
          {
            tag: "context menu",
            shell: {
              "popupMenuOpen": true
            },
            expected: "open:popupMenu"
          },
          {
            tag: "tray menu over the tray drawer",
            shell: {
              "opened": panel({}),
              "popupMenuOpen": true
            },
            expected: "open:popupMenu"
          },
          {
            tag: "radial menu",
            shell: {
              "radialMenuOpen": true
            },
            expected: "open:radialMenu"
          },
          {
            tag: "edit desktop animating",
            shell: {
              "editDesktopProgress": 0.4
            },
            expected: "busy"
          },
          {
            tag: "edit desktop on",
            shell: {
              "editDesktopProgress": 1
            },
            expected: "open:editDesktop"
          }
        ];
  }

  function test_state(data) {
    compare(PanelSettle.state(data.shell), data.expected);
  }
}
