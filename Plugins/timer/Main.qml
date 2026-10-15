import QtQuick
import Quickshell
import Quickshell.Io
import "Pomodoro.js" as Pomodoro
import "TimerLogic.js" as TimerLogic
import qs.Commons
import qs.Services.System
import qs.Services.UI

Item {
  id: root

  property var pluginApi: null

  IpcHandler {
    target: "plugin:timer"

    function toggle() {
      if (pluginApi) {
        pluginApi.withCurrentScreen(screen => {
          pluginApi.togglePanel(screen);
        });
      }
    }

    function start(duration_str: string) {
      if (duration_str && duration_str === "stopwatch") {
        root.stopwatchReset();
        root.timerMode = "stopwatch";
        root.stopwatchStart();
      } else if (duration_str === "pomodoro") {
        root.timerMode = "pomodoro";
        root.pomodoroReset();
        root.pomodoroStart();
      } else if (duration_str && duration_str !== "") {
        const seconds = root.parseDuration(duration_str);
        if (seconds > 0) {
          root.countdownReset();
          root.cdRemainingSeconds = seconds;
          root.timerMode = "countdown";
          root.countdownStart();
        }
      } else {
        root.timerStart();
      }
    }

    function pause() {
      root.timerPause();
    }

    function stats(): string {
      root.recordStudyTime(Date.now());
      root.saveStudyTime();
      return JSON.stringify({
                              studySecondsByDay: root.studySecondsByDay,
                              stats: root.studyStats
                            });
    }

    function reset() {
      root.timerReset();
    }
  }

  // View mode (which tab is active in the panel)
  property string timerMode: TimerLogic.modeAt(0)
  readonly property bool timerStopwatchMode: timerMode === "stopwatch"
  readonly property bool timerPomodoroMode: timerMode === "pomodoro"

  property var studySecondsByDay: ({})
  property real studyLastTimestamp: 0
  property real studyLastSaved: 0
  property bool studyDirty: false
  property bool studyReady: false
  readonly property var studyStats: Pomodoro.stats(studySecondsByDay, timestamp * 1000)

  function recordStudyTime(now) {
    if (!pmRunning || studyLastTimestamp <= 0)
      return;
    studySecondsByDay = Pomodoro.addStudyTime(studySecondsByDay, pmState, studyLastTimestamp, now, pmWorkMinutes, pmBreakMinutes);
    studyLastTimestamp = now;
    studyDirty = true;
  }

  function saveStudyTime() {
    if (!studyReady || !studyDirty || !pluginApi)
      return;
    pluginApi.pluginSettings.studySecondsByDay = Object.assign({}, studySecondsByDay);
    pluginApi.saveSettings();
    studyDirty = false;
    studyLastSaved = Date.now();
  }

  Component.onDestruction: {
    recordStudyTime(Date.now());
    saveStudyTime();
  }

  property var pmState: null
  readonly property int pmWorkMinutes: Pomodoro.minutes(pluginApi?.pluginSettings?.pomodoroWorkMinutes, 50)
  readonly property int pmBreakMinutes: Pomodoro.minutes(pluginApi?.pluginSettings?.pomodoroBreakMinutes, 10)
  readonly property bool pmRunning: pmState !== null && pmState.running
  readonly property string pmPhase: pmState ? pmState.phase : "work"
  readonly property int pmRemainingSeconds: Math.ceil((pmState ? pmState.remainingMs : pmWorkMinutes * 60000) / 1000)
  readonly property int pmTotalSeconds: Pomodoro.duration(pmPhase, pmWorkMinutes, pmBreakMinutes) / 1000

  onPmWorkMinutesChanged: pomodoroReset()
  onPmBreakMinutesChanged: pomodoroReset()

  function setPomodoroDuration(phase, value) {
    if (!pluginApi)
      return;
    const key = phase === "work" ? "pomodoroWorkMinutes" : "pomodoroBreakMinutes";
    const normalized = Pomodoro.minutes(value, phase === "work" ? 50 : 10);
    if (normalized === (phase === "work" ? pmWorkMinutes : pmBreakMinutes))
      return;
    pomodoroPause();
    pomodoroReset();
    pluginApi.pluginSettings[key] = normalized;
    pluginApi.saveSettings();
  }

  function pomodoroStart() {
    if (pmRunning)
      return;
    studyLastTimestamp = Date.now();
    pmState = Pomodoro.start(pmState || Pomodoro.create(pmWorkMinutes), studyLastTimestamp);
  }

  function pomodoroPause() {
    recordStudyTime(Date.now());
    saveStudyTime();
    if (pmState)
      pmState = Pomodoro.pause(pmState, Date.now(), pmWorkMinutes, pmBreakMinutes);
  }

  function pomodoroReset() {
    recordStudyTime(Date.now());
    saveStudyTime();
    studyLastTimestamp = 0;
    pmState = null;
  }

  // Countdown state
  property bool cdRunning: false
  property int cdRemainingSeconds: 0
  property int cdTotalSeconds: 0
  property int cdStartTimestamp: 0
  property int cdPausedAt: 0
  property bool cdSoundPlaying: false

  // Stopwatch state
  property bool swRunning: false
  property int swElapsedSeconds: 0
  property int swStartTimestamp: 0
  property int swPausedAt: 0

  // Backward-compatible computed properties (used by bar/CC widgets)
  readonly property bool timerRunning: timerPomodoroMode ? pmRunning : (timerStopwatchMode ? swRunning : cdRunning)
  readonly property int timerRemainingSeconds: timerPomodoroMode ? pmRemainingSeconds : cdRemainingSeconds
  readonly property int timerTotalSeconds: timerPomodoroMode ? pmTotalSeconds : cdTotalSeconds
  readonly property int timerElapsedSeconds: swElapsedSeconds
  readonly property bool timerSoundPlaying: !timerStopwatchMode && !timerPomodoroMode && cdSoundPlaying

  // Current timestamp
  property int timestamp: Math.floor(Date.now() / 1000)

  // Main timer loop
  Timer {
    id: updateTimer
    interval: 1000
    repeat: true
    running: true
    triggeredOnStart: false
    onTriggered: {
      var now = new Date();
      root.timestamp = Math.floor(now.getTime() / 1000);

      // Update countdown if running
      if (root.cdRunning && root.cdStartTimestamp > 0) {
        const elapsed = root.timestamp - root.cdStartTimestamp;
        root.cdRemainingSeconds = root.cdTotalSeconds - elapsed;
        if (root.cdRemainingSeconds <= 0) {
          root.countdownOnFinished();
        }
      }

      // Update stopwatch if running
      if (root.swRunning && root.swStartTimestamp > 0) {
        const elapsed = root.timestamp - root.swStartTimestamp;
        root.swElapsedSeconds = root.swPausedAt + elapsed;
      }

      if (root.pmRunning) {
        const crossedBoundary = now.getTime() >= root.pmState.deadline;
        root.recordStudyTime(now.getTime());
        root.pmState = Pomodoro.advance(root.pmState, now.getTime(), root.pmWorkMinutes, root.pmBreakMinutes);
        if (crossedBoundary || now.getTime() - root.studyLastSaved >= 15000)
          root.saveStudyTime();
        if (crossedBoundary) {
          SoundService.playSound("alarm-beep.wav", {
                                   volume: 0.3
                                 });
          ToastService.showNotice(pluginApi?.tr("panel.pomodoro"), pluginApi?.tr(root.pmPhase === "work" ? "pomodoro.work-started" : "pomodoro.break-started"), "clock");
        }
      }

      // Sync to next second
      var msIntoSecond = now.getMilliseconds();
      if (msIntoSecond > 100) {
        updateTimer.interval = 1000 - msIntoSecond + 10;
        updateTimer.restart();
      } else {
        updateTimer.interval = 1000;
      }
    }
  }

  Component.onCompleted: {
    studySecondsByDay = Object.assign({}, pluginApi?.pluginSettings?.studySecondsByDay || {});
    studyReady = true;
    studyLastSaved = Date.now();
    // Sync start
    var now = new Date();
    var msUntilNextSecond = 1000 - now.getMilliseconds();
    updateTimer.interval = msUntilNextSecond + 10;
    updateTimer.restart();
  }

  // Countdown logic
  function countdownStart() {
    if (root.cdRemainingSeconds <= 0)
      return;
    root.cdTotalSeconds = root.cdRemainingSeconds;
    root.cdStartTimestamp = root.timestamp;
    root.cdPausedAt = 0;
    root.cdRunning = true;
  }

  function countdownPause() {
    if (root.cdRunning) {
      const currentTimestamp = Math.floor(Date.now() / 1000);
      const elapsed = currentTimestamp - root.cdStartTimestamp;
      const remaining = root.cdTotalSeconds - elapsed;
      root.cdPausedAt = Math.max(0, remaining);
      root.cdRemainingSeconds = root.cdPausedAt;
    }
    root.cdRunning = false;
    root.cdStartTimestamp = 0;
    SoundService.stopSound("alarm-beep.wav");
    root.cdSoundPlaying = false;
  }

  function countdownReset() {
    root.cdRunning = false;
    root.cdStartTimestamp = 0;
    root.cdRemainingSeconds = 0;
    root.cdTotalSeconds = 0;
    root.cdPausedAt = 0;
    SoundService.stopSound("alarm-beep.wav");
    root.cdSoundPlaying = false;
  }

  // Stopwatch logic
  function stopwatchStart() {
    root.swStartTimestamp = root.timestamp;
    root.swPausedAt = root.swElapsedSeconds;
    root.swRunning = true;
  }

  function stopwatchPause() {
    if (root.swRunning) {
      root.swPausedAt = root.swElapsedSeconds;
    }
    root.swRunning = false;
    root.swStartTimestamp = 0;
  }

  function stopwatchReset() {
    root.swRunning = false;
    root.swStartTimestamp = 0;
    root.swElapsedSeconds = 0;
    root.swPausedAt = 0;
  }

  // Convenience: operate on current mode
  function timerStart() {
    if (root.timerPomodoroMode)
      pomodoroStart();
    else if (root.timerStopwatchMode)
      stopwatchStart();
    else
      countdownStart();
  }

  function timerPause() {
    if (root.timerPomodoroMode)
      pomodoroPause();
    else if (root.timerStopwatchMode)
      stopwatchPause();
    else
      countdownPause();
  }

  function timerReset() {
    if (root.timerPomodoroMode)
      pomodoroReset();
    else if (root.timerStopwatchMode)
      stopwatchReset();
    else
      countdownReset();
  }

  function parseDuration(duration_str) {
    if (!duration_str)
      return 0;

    // Default to minutes if just a number
    if (/^\d+$/.test(duration_str)) {
      return parseInt(duration_str) * 60;
    }

    var totalSeconds = 0;
    var regex = /(\d+)([hms])/g;
    var match;

    while ((match = regex.exec(duration_str)) !== null) {
      var value = parseInt(match[1]);
      var unit = match[2];

      if (unit === 'h')
        totalSeconds += value * 3600;
      else if (unit === 'm')
        totalSeconds += value * 60;
      else if (unit === 's')
        totalSeconds += value;
    }

    return totalSeconds;
  }

  function countdownOnFinished() {
    root.cdRunning = false;
    root.cdRemainingSeconds = 0;
    root.cdSoundPlaying = true;
    SoundService.playSound("alarm-beep.wav", {
                             repeat: true,
                             volume: 0.3
                           });
    ToastService.showNotice(pluginApi?.tr("toast.title") || "Timer", pluginApi?.tr("toast.finished") || "Timer finished!", "hourglass", {
                              onDismissed: () => {
                                if (root.cdSoundPlaying) {
                                  root.countdownPause();
                                }
                              }
                            });
  }
}
