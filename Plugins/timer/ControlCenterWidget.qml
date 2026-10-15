import QtQuick
import Quickshell
import qs.Commons
import qs.Widgets

NIconButton {
  property ShellScreen screen
  property var pluginApi: null
  readonly property var mainInstance: pluginApi?.mainInstance

  icon: {
    if (mainInstance && mainInstance.timerSoundPlaying)
      return "bell-ringing";
    if (mainInstance && mainInstance.timerPomodoroMode)
      return "clock";
    if (mainInstance && mainInstance.timerStopwatchMode)
      return "stopwatch";
    return "hourglass";
  }

  tooltipText: {
    if (!mainInstance)
      return "Timer";
    if (mainInstance.timerSoundPlaying)
      return "Timer Finished!";
    if (mainInstance.timerPomodoroMode) {
      return pluginApi?.tr("panel.pomodoro") + " · " + pluginApi?.tr(mainInstance.pmPhase === "break" ? "pomodoro.break" : "pomodoro.work");
    }
    if (mainInstance.timerStopwatchMode) {
      return mainInstance.timerRunning ? "Stopwatch Running" : "Stopwatch";
    }
    return mainInstance.timerRunning ? "Timer Running" : "Timer";
  }

  colorFg: {
    if (mainInstance && (mainInstance.timerRunning || mainInstance.timerSoundPlaying)) {
      return Color.mOnPrimary;
    }
    return Color.mPrimary;
  }

  colorBg: {
    if (mainInstance && (mainInstance.timerRunning || mainInstance.timerSoundPlaying)) {
      return Color.mPrimary;
    }
    return Style.capsuleColor;
  }

  onClicked: {
    if (pluginApi) {
      pluginApi.togglePanel(screen);
    }
  }
}
