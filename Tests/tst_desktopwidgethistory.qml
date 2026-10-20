import QtQuick
import QtTest
import "../Helpers/DesktopWidgetHistory.js" as History

TestCase {
  name: "DesktopWidgetHistory"

  function test_movesResizesSettingsAddsAndDeletesAcrossMonitors() {
    const initial = [
            {
              name: "DP-1",
              widgets: [
                {
                  id: "Weather",
                  x: 100,
                  y: 200,
                  scale: 1
                }
              ]
            },
            {
              name: "DP-2",
              widgets: []
            }
          ];
    let history = History.create(initial);
    const states = [History.snapshot(initial)];
    let next = History.snapshot(initial);
    next[0].widgets[0].x = 200;
    states.push(History.snapshot(next));
    next[0].widgets[0].scale = 1.5;
    states.push(History.snapshot(next));
    next[0].widgets[0].view = "hourly";
    states.push(History.snapshot(next));
    next[1].widgets.push({
                           id: "WeatherDetails",
                           detail: "moon"
                         });
    states.push(History.snapshot(next));
    next[0].widgets.splice(0, 1);
    states.push(History.snapshot(next));
    for (let i = 1; i < states.length; i++)
      history = History.record(history, states[i]);
    for (let i = states.length - 2; i >= 0; i--) {
      history = History.undo(history);
      compare(history.current, states[i]);
    }
    verify(History.undo(history) === history);
    for (let i = 1; i < states.length; i++) {
      history = History.redo(history);
      compare(history.current, states[i]);
    }
    verify(History.redo(history) === history);
  }

  function test_independentResizeIsOneUndoStep() {
    const initial = [
            {
              widgets: [
                {
                  id: "SystemStat",
                  x: 100,
                  y: 200,
                  scale: 1,
                  widthScale: 1,
                  heightScale: 1
                }
              ]
            }
          ];
    const resized = History.snapshot(initial);
    resized[0].widgets[0].widthScale = 1.5;
    resized[0].widgets[0].heightScale = 2;
    resized[0].widgets[0].x = -20;
    let history = History.record(History.create(initial), resized);
    compare(history.past.length, 1);
    history = History.undo(history);
    compare(history.current, initial);
    history = History.redo(history);
    compare(history.current, resized);
  }

  function test_duplicateNotificationsDoNotEraseRedo() {
    let history = History.create([
                                   {
                                     x: 1
                                   }
                                 ]);
    history = History.record(history, [
                               {
                                 x: 2
                               }
                             ]);
    history = History.undo(history);
    verify(History.record(history, [
                            {
                              x: 1
                            }
                          ]) === history);
    compare(history.future.length, 1);
    history = History.record(history, [
                               {
                                 x: 3
                               }
                             ]);
    compare(history.future.length, 0);
    compare(History.undo(history).current, [
              {
                x: 1
              }
            ]);
  }

  function test_snapshotsDoNotShareMutableSettings() {
    const layout = [
            {
              widgets: [
                {
                  scale: 1
                }
              ]
            }
          ];
    let history = History.create(layout);
    layout[0].widgets[0].scale = 2;
    compare(history.current[0].widgets[0].scale, 1);
    history = History.record(history, layout);
    layout[0].widgets[0].scale = 3;
    compare(history.current[0].widgets[0].scale, 2);
    compare(history.past[0][0].widgets[0].scale, 1);
  }

  function test_historyIsBoundedAndNoOpDoesNotAddStep() {
    let history = History.create([]);
    verify(History.record(history, []) === history);
    for (let i = 1; i <= 80; i++)
      history = History.record(history, [
                                 {
                                   x: i
                                 }
                               ]);
    compare(history.past.length, History.limit);
    compare(history.current, [
              {
                x: 80
              }
            ]);
    for (let i = 0; i < History.limit; i++)
      history = History.undo(history);
    compare(history.current, [
              {
                x: 20
              }
            ]);
  }
}
