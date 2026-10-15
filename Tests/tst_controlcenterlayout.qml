import QtQuick
import QtTest
import "../Helpers/ControlCenterLayout.js" as ControlCenterLayout
import "../Helpers/UiStyles.js" as UiStyles

TestCase {
  name: "ControlCenterLayout"

  function test_rowsPreserveSettingsAndPackFiveCells() {
    const custom = {
      id: "CustomButton",
      onClicked: "echo hello"
    };
    const rows = ControlCenterLayout.shortcutRows([
                                                    {
                                                      id: "Network"
                                                    },
                                                    {
                                                      id: "Bluetooth"
                                                    },
                                                    custom], [
                                                    {
                                                      id: "Notifications"
                                                    },
                                                    {
                                                      id: "PowerProfile"
                                                    },
                                                    {
                                                      id: "plugin:test"
                                                    }
                                                  ]);
    compare(rows.map(row => row.map(entry => entry.span)), [[1, 2, 1, 1], [2, 1]]);
    compare(rows[0][2].settings, custom);
    compare(rows[1][1].index, 5);
    for (const row of rows)
      verify(row.reduce((total, entry) => total + entry.span, 0) <= ControlCenterLayout.columns);
    compare(ControlCenterLayout.shortcutRows(null, [null,
                                                    {},
                                                    {
                                                      id: ""
                                                    }
                                             ]), []);
  }

  function test_gridWidthsDoNotOverflow_data() {
    return [
          {
            tag: "regular",
            width: 400,
            gap: 4
          },
          {
            tag: "scaled",
            width: 520,
            gap: 6
          },
          {
            tag: "minimum",
            width: 120,
            gap: 4
          }
        ];
  }
  function test_gridWidthsDoNotOverflow(data) {
    compare(ControlCenterLayout.cellWidth(data.width, data.gap, 2) * 2 + ControlCenterLayout.cellWidth(data.width, data.gap, 1) + data.gap * 2, data.width);
    compare(ControlCenterLayout.cellWidth(data.width, data.gap, 1) * 5 + data.gap * 4, data.width);
    compare(ControlCenterLayout.cellWidth(0, 4, 1), 0);
  }

  function test_actionsForwardAllButtonsAndRespectDisabled() {
    const counts = {
      left: 0,
      right: 0,
      middle: 0
    };
    const action = {
      enabled: true,
      clicked: () => counts.left++,
      rightClicked: () => counts.right++,
      middleClicked: () => counts.middle++
    };
    verify(ControlCenterLayout.invoke(action, "left"));
    verify(ControlCenterLayout.invoke(action, "right"));
    verify(ControlCenterLayout.invoke(action, "middle"));
    compare(counts, {
              left: 1,
              right: 1,
              middle: 1
            });
    action.enabled = false;
    verify(!ControlCenterLayout.invoke(action, "left"));
    compare(counts.left, 1);
    verify(!ControlCenterLayout.invoke(null, "left"));
    verify(!ControlCenterLayout.invoke({}, "left"));
  }

  function test_mediaProgress_data() {
    return [
          {
            tag: "normal",
            position: 60,
            length: 240,
            want: 0.25
          },
          {
            tag: "no track",
            position: 10,
            length: 0,
            want: 0
          },
          {
            tag: "invalid position",
            position: NaN,
            length: 240,
            want: 0
          },
          {
            tag: "invalid length",
            position: 60,
            length: Infinity,
            want: 0
          },
          {
            tag: "past end",
            position: 400,
            length: 240,
            want: 1
          },
          {
            tag: "before start",
            position: -2,
            length: 240,
            want: 0
          }
        ];
  }
  function test_mediaProgress(data) {
    compare(ControlCenterLayout.progress(data.position, data.length), data.want);
  }

  function test_styleViewsAreExplicitAndDifferent() {
    for (const surface of ["controlCenter", "mediaCard", "mediaPlayer", "osd", "notificationContent"]) {
      verify(UiStyles.view("caelestia", surface).length > 0);
      verify(UiStyles.view("material", surface).length > 0);
      verify(UiStyles.view("caelestia", surface) !== UiStyles.view("material", surface));
      compare(UiStyles.view("unknown", surface), UiStyles.view("caelestia", surface));
    }
    compare(UiStyles.view("material", "unknown"), "");
  }

  function test_notificationFeedUsesSpaceForActualContent() {
    compare(ControlCenterLayout.notificationHeight(0, 1), 132);
    compare(ControlCenterLayout.notificationHeight(1, 1), 180);
    compare(ControlCenterLayout.notificationHeight(10, 1), 300);
    compare(ControlCenterLayout.notificationHeight(0, 1.25), 165);
  }

  function test_disabledCardsStayDisabled() {
    const cards = [
            {
              id: "audio-card",
              enabled: true
            },
            {
              id: "brightness-card",
              enabled: false
            }
          ];
    verify(ControlCenterLayout.cardEnabled(cards, "audio-card"));
    verify(!ControlCenterLayout.cardEnabled(cards, "brightness-card"));
    verify(!ControlCenterLayout.cardEnabled(cards, "unknown"));
    verify(!ControlCenterLayout.cardEnabled(null, "audio-card"));
  }

  function test_cardOrderAndAvailability() {
    const cards = [
            {
              id: "notification-card",
              enabled: true
            },
            {
              id: "brightness-card",
              enabled: true
            },
            {
              id: "audio-card",
              enabled: true
            },
            {
              id: "calendar-month-card",
              enabled: false
            },
            {
              id: "weather-card",
              enabled: true
            },
            {
              id: "shortcuts-card",
              enabled: true
            },
            {
              id: "media-sysmon-card",
              enabled: false
            },
            {
              id: "unknown",
              enabled: true
            },
            null];
    compare(ControlCenterLayout.visibleCards(cards, false, false).map(card => card.id), ["notification-card", "brightness-card", "audio-card"]);
    compare(ControlCenterLayout.visibleCards(cards, true, true).map(card => card.id), ["notification-card", "brightness-card", "audio-card", "weather-card", "shortcuts-card"]);
    compare(ControlCenterLayout.visibleCards(null, true, true), []);
    compare(ControlCenterLayout.visibleCards([
                                               {
                                                 id: "calendar-month-card",
                                                 enabled: true
                                               }
                                             ], false, false).length, 1);
  }

  function test_additionalCardsPreserveSavedOrderAndDisabledState() {
    const saved = [
            {
              id: "audio-card",
              enabled: false
            },
            {
              id: "notification-card",
              enabled: false
            }
          ];
    const migrated = ControlCenterLayout.withAdditionalCards(saved);
    compare(migrated, [saved[0], saved[1],
                       {
                         id: "calendar-month-card",
                         enabled: true
                       }
            ]);
    compare(saved.length, 2);
    compare(ControlCenterLayout.withAdditionalCards(migrated), migrated);
    compare(ControlCenterLayout.withAdditionalCards(null), [
              {
                id: "notification-card",
                enabled: true
              },
              {
                id: "calendar-month-card",
                enabled: true
              }
            ]);
  }
}
