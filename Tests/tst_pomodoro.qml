import QtQuick
import QtTest
import "../Plugins/timer/Pomodoro.js" as Pomodoro
import "../Plugins/timer/TimerLogic.js" as TimerLogic

TestCase {
  name: "Pomodoro"

  function test_modeOrderAndDefault() {
    compare(TimerLogic.modeAt(0), "stopwatch");
    compare(TimerLogic.modeAt(1), "pomodoro");
    compare(TimerLogic.modeAt(2), "countdown");
    compare(TimerLogic.modeIndex("stopwatch"), 0);
    compare(TimerLogic.modeIndex("pomodoro"), 1);
    compare(TimerLogic.modeIndex("countdown"), 2);
    compare(TimerLogic.modeIndex(undefined), 0);
    compare(TimerLogic.nextMode("stopwatch"), "pomodoro");
    compare(TimerLogic.nextMode("pomodoro"), "countdown");
    compare(TimerLogic.nextMode("countdown"), "stopwatch");
  }

  function test_defaultsAndValidation() {
    compare(Pomodoro.create(undefined).remainingMs, 50 * 60000);
    compare(Pomodoro.duration("break", undefined, undefined), 10 * 60000);
    compare(Pomodoro.minutes(0, 50), 50);
    compare(Pomodoro.minutes("invalid", 10), 10);
    compare(Pomodoro.minutes(1000, 50), 180);
    compare(Pomodoro.minutes(25.9, 50), 25);
  }

  function test_transitions_data() {
    return [
          {
            tag: "initial",
            elapsed: 0,
            phase: "work",
            remaining: 3000
          },
          {
            tag: "work ticking",
            elapsed: 17,
            phase: "work",
            remaining: 2983
          },
          {
            tag: "break boundary",
            elapsed: 3000,
            phase: "break",
            remaining: 600
          },
          {
            tag: "break ticking",
            elapsed: 3010,
            phase: "break",
            remaining: 590
          },
          {
            tag: "next work",
            elapsed: 3600,
            phase: "work",
            remaining: 3000
          },
          {
            tag: "long suspend",
            elapsed: 3600000 + 3010,
            phase: "break",
            remaining: 590
          }
        ];
  }

  function test_transitions(data) {
    const state = Pomodoro.start(Pomodoro.create(50), 1000);
    const next = Pomodoro.advance(state, 1000 + data.elapsed * 1000, 50, 10);
    compare(next.phase, data.phase);
    compare(next.remainingMs, data.remaining * 1000);
    verify(next.running);
    compare(state.phase, "work");
  }

  function test_pauseAndResume() {
    let state = Pomodoro.start(Pomodoro.create(1), 1000);
    state = Pomodoro.pause(state, 61500, 1, 2);
    compare(state.phase, "break");
    compare(state.remainingMs, 119500);
    verify(!state.running);
    compare(Pomodoro.advance(state, 999999, 1, 2), state);
    state = Pomodoro.start(state, 1000000);
    compare(state.deadline, 1119500);
    compare(Pomodoro.advance(state, 1119500, 1, 2).phase, "work");
  }

  function test_customDurations() {
    const state = Pomodoro.start(Pomodoro.create(25), 0);
    const next = Pomodoro.advance(state, 25 * 60000, 25, 5);
    compare(next.phase, "break");
    compare(next.remainingMs, 5 * 60000);
  }

  function test_format() {
    compare(Pomodoro.formatRemaining(3000000), "50:00");
    compare(Pomodoro.formatRemaining(59999), "01:00");
    compare(Pomodoro.formatRemaining(-10), "00:00");
    compare(Pomodoro.formatStudyTime(3720), "1h 02m");
    compare(Pomodoro.formatStudyCompact(0), "0m");
    compare(Pomodoro.formatStudyCompact(3599), "59m");
    compare(Pomodoro.formatStudyCompact(3600), "1h00");
    compare(Pomodoro.formatStudyCompact(3720), "1h02");
    compare(Pomodoro.formatStudyCompact(360000), "100h00");
  }

  function test_workOnlyAndMultipleCycles() {
    let state = Pomodoro.start(Pomodoro.create(50), 0);
    compare(Pomodoro.workMilliseconds(state, 0, 3600000, 50, 10), 3000000);
    compare(Pomodoro.workMilliseconds(state, 0, 7200000, 50, 10), 6000000);
    compare(Pomodoro.workMilliseconds(state, 3000000, 3600000, 50, 10), 0);
    state = Pomodoro.advance(state, 3100000, 50, 10);
    compare(Pomodoro.workMilliseconds(state, 3100000, 3660000, 50, 10), 60000);
    state = Pomodoro.pause(state, 3660000, 50, 10);
    compare(Pomodoro.workMilliseconds(state, 3660000, 9999999, 50, 10), 0);
  }

  function test_dailyHistoryAndPersistence() {
    const start = new Date(2026, 9, 6, 23, 59, 30).getTime();
    const state = Pomodoro.start(Pomodoro.create(1), start);
    const original = {
      "2026-10-05": 120
    };
    const totals = Pomodoro.addStudyTime(original, state, start, start + 180000, 1, 1);
    compare(totals["2026-10-06"], 30);
    compare(totals["2026-10-07"], 90);
    compare(totals["2026-10-05"], 120);
    compare(Object.keys(original).length, 1);
    const restored = JSON.parse(JSON.stringify(totals));
    compare(restored, totals);
    compare(Pomodoro.stats(restored, start + 180000).totalSeconds, 240);
  }

  function test_fractionalUpdatesAndPausedGaps() {
    const start = new Date(2026, 9, 6, 12).getTime();
    let state = Pomodoro.start(Pomodoro.create(50), start);
    let totals = Pomodoro.addStudyTime({}, state, start, start + 250, 50, 10);
    totals = Pomodoro.addStudyTime(totals, state, start + 250, start + 500, 50, 10);
    state = Pomodoro.pause(state, start + 500, 50, 10);
    totals = Pomodoro.addStudyTime(totals, state, start + 500, start + 100000, 50, 10);
    state = Pomodoro.start(state, start + 100000);
    totals = Pomodoro.addStudyTime(totals, state, start + 100000, start + 100500, 50, 10);
    compare(totals["2026-10-06"], 1);
  }

  function test_statsAndStreak() {
    const now = new Date(2026, 9, 6, 12).getTime();
    const totals = {
      "2026-10-03": 180,
      "2026-10-04": 3600,
      "2026-10-05": 120,
      "2026-10-06": 30
    };
    let stats = Pomodoro.stats(totals, now);
    compare(stats.streak, 3);
    compare(stats.todaySeconds, 30);
    compare(stats.bestSeconds, 3600);
    compare(stats.days, 3);
    compare(stats.xp, 650);
    totals["2026-10-06"] = 60;
    compare(Pomodoro.stats(totals, now).streak, 4);
    compare(Pomodoro.stats({}, now).streak, 0);
    compare(Pomodoro.stats(totals, new Date(2026, 9, 8).getTime()).streak, 0);
  }

  function test_widgetsFollowSelectedMode() {
    const state = {
      timerPomodoroMode: true,
      timerStopwatchMode: false,
      pmState: {},
      pmRemainingSeconds: 1500,
      pmTotalSeconds: 3000,
      cdRunning: true,
      cdRemainingSeconds: 42,
      cdTotalSeconds: 60,
      swElapsedSeconds: 123,
      swRunning: false
    };
    verify(TimerLogic.isActive(state));
    compare(TimerLogic.displaySeconds(state), 1500);
    compare(TimerLogic.progress(state), 0.5);
    compare(TimerLogic.verticalLines(TimerLogic.displaySeconds(state)), ["25", "00"]);
    state.pmState = null;
    verify(!TimerLogic.isActive(state));
    state.timerPomodoroMode = false;
    state.timerStopwatchMode = true;
    compare(TimerLogic.displaySeconds(state), 123);
    compare(TimerLogic.progress(state), 3 / 60);
    state.swElapsedSeconds = 0;
    // Another mode running must not make an idle stopwatch appear active.
    verify(!TimerLogic.isActive(state));
    state.timerStopwatchMode = false;
    compare(TimerLogic.displaySeconds(state), 42);
    compare(TimerLogic.progress(state), 0.7);
    verify(TimerLogic.isActive(state));
  }
}
