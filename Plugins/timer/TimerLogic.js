.pragma library

// Pure helpers shared by the bar and desktop widgets. `state` is the plugin's
// main instance (or any object with the same countdown/stopwatch fields).

function pad2(n) {
  return n.toString().padStart(2, "0");
}

// True while a countdown or stopwatch has something to show
function isActive(state) {
  if (!state)
    return false;
  if (state.timerPomodoroMode)
    return state.pmState !== null && state.pmState !== undefined;
  if (state.timerStopwatchMode)
    return !!(state.swRunning || state.swElapsedSeconds > 0);
  return !!(state.cdRunning || state.cdSoundPlaying || state.cdRemainingSeconds > 0);
}

// Seconds shown for the current mode
function displaySeconds(state) {
  if (!state)
    return 0;
  return Math.max(0, state.timerPomodoroMode ? state.pmRemainingSeconds : (state.timerStopwatchMode ? state.swElapsedSeconds : state.cdRemainingSeconds));
}

// "MM:SS", or "H:MM:SS" from one hour on
function formatClock(seconds) {
  var s = Math.max(0, Math.floor(seconds || 0));
  var h = Math.floor(s / 3600);
  var m = Math.floor((s % 3600) / 60);
  var sec = s % 60;
  if (h > 0)
    return h + ":" + pad2(m) + ":" + pad2(sec);
  return pad2(m) + ":" + pad2(sec);
}

// Two short lines for a vertical bar: minutes/seconds, or hours/minutes from one hour on
function verticalLines(seconds) {
  var s = Math.max(0, Math.floor(seconds || 0));
  var h = Math.floor(s / 3600);
  var m = Math.floor((s % 3600) / 60);
  if (h > 0)
    return [h + "h", pad2(m)];
  return [pad2(m), pad2(s % 60)];
}

// Ring fill in [0, 1]: remaining share of a countdown, or the current minute of a stopwatch
function progress(state) {
  if (!state)
    return 0;
  if (state.timerPomodoroMode)
    return state.pmTotalSeconds > 0 ? Math.max(0, Math.min(1, state.pmRemainingSeconds / state.pmTotalSeconds)) : 0;
  if (state.timerStopwatchMode)
    return (Math.max(0, state.swElapsedSeconds) % 60) / 60;
  if (!(state.cdTotalSeconds > 0))
    return 0;
  return Math.max(0, Math.min(1, state.cdRemainingSeconds / state.cdTotalSeconds));
}

// New countdown duration after scrolling `steps` notches of `stepSeconds`, never negative
function adjustDuration(seconds, steps, stepSeconds) {
  return Math.max(0, Math.floor(seconds || 0) + steps * stepSeconds);
}

var modes = ["stopwatch", "pomodoro", "countdown"];

function modeAt(index) {
  return modes[index] || modes[0];
}

function modeIndex(mode) {
  return Math.max(0, modes.indexOf(mode));
}

function nextMode(mode) {
  return modeAt((modeIndex(mode) + 1) % modes.length);
}
