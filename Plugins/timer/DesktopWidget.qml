import QtQuick
import QtQuick.Layouts
import Quickshell
import "TimerLogic.js" as TimerLogic
import qs.Commons
import qs.Modules.DesktopWidgets
import qs.Widgets

DraggableDesktopWidget {
  id: root

  property var pluginApi: null
  readonly property var mainInstance: pluginApi?.mainInstance

  readonly property bool stopwatchMode: mainInstance ? mainInstance.timerStopwatchMode : false
  readonly property bool running: mainInstance ? mainInstance.timerRunning : false
  readonly property bool ringing: mainInstance ? mainInstance.timerSoundPlaying : false
  readonly property int shownSeconds: TimerLogic.displaySeconds(mainInstance)
  readonly property string timeText: TimerLogic.formatClock(shownSeconds)
  readonly property real ratio: TimerLogic.progress(mainInstance)
  // A countdown can only be edited while it is not running
  readonly property bool canEditDuration: mainInstance && !stopwatchMode && !mainInstance.timerPomodoroMode && !running && !ringing
  readonly property bool canStart: running || ringing || stopwatchMode || (mainInstance && mainInstance.timerPomodoroMode) || (mainInstance && mainInstance.cdRemainingSeconds > 0)

  // Same footprint as the analog/binary desktop clock (see DesktopClock.qml)
  readonly property real fontSize: Math.round(Style.fontSizeXXXL * 2.5 * widgetScale)
  readonly property real contentPadding: Math.round(Style.marginXL * widgetScale)
  readonly property real faceSize: Math.round(fontSize * 1.9)
  implicitWidth: Math.round(faceSize + contentPadding * 2)
  implicitHeight: implicitWidth
  width: implicitWidth
  height: implicitHeight

  Item {
    id: face
    anchors.centerIn: parent
    width: root.faceSize
    height: root.faceSize
    z: 2

    Canvas {
      id: ring
      anchors.fill: parent

      readonly property real lineWidth: Math.max(2, Math.round(5 * root.widgetScale))
      readonly property real progressRatio: root.ratio
      readonly property color trackColor: Qt.alpha(Color.mOnSurface, 0.1)
      readonly property color fillColor: root.ringing ? Color.mError : Color.mPrimary

      onProgressRatioChanged: requestPaint()
      onFillColorChanged: requestPaint()
      onTrackColorChanged: requestPaint()
      onWidthChanged: requestPaint()

      onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        var r = Math.min(width, height) / 2 - lineWidth / 2;
        if (r <= 0)
          return;
        ctx.lineWidth = lineWidth;
        ctx.beginPath();
        ctx.arc(width / 2, height / 2, r, 0, 2 * Math.PI);
        ctx.strokeStyle = trackColor;
        ctx.stroke();
        if (progressRatio > 0) {
          ctx.beginPath();
          ctx.arc(width / 2, height / 2, r, -Math.PI / 2, -Math.PI / 2 + progressRatio * 2 * Math.PI);
          ctx.strokeStyle = fillColor;
          ctx.lineCap = "round";
          ctx.stroke();
        }
      }
    }

    // Scroll to set the countdown, one minute per notch
    WheelHandler {
      acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
      enabled: root.canEditDuration
      onWheel: event => {
        if (event.angleDelta.y === 0)
          return;
        root.mainInstance.cdRemainingSeconds = TimerLogic.adjustDuration(root.mainInstance.cdRemainingSeconds, event.angleDelta.y > 0 ? 1 : -1, 60);
        event.accepted = true;
      }
    }

    ColumnLayout {
      anchors.centerIn: parent
      spacing: Math.round(Style.marginXXS * root.widgetScale)

      // Switches between countdown and stopwatch while nothing is running
      NIconButton {
        Layout.alignment: Qt.AlignHCenter
        baseSize: Math.round(22 * root.widgetScale)
        applyUiScale: false
        icon: root.ringing ? "bell-ringing" : (root.mainInstance?.timerPomodoroMode ? "clock" : (root.stopwatchMode ? "stopwatch" : "hourglass"))
        tooltipText: root.pluginApi?.tr("panel." + (root.stopwatchMode ? "pomodoro" : (root.mainInstance?.timerPomodoroMode ? "countdown" : "stopwatch")))
        colorBg: "transparent"
        colorFg: root.ringing ? Color.mError : Color.mOnSurfaceVariant
        border.width: 0
        enabled: root.mainInstance && !root.running && !root.ringing
        onClicked: root.mainInstance.timerMode = TimerLogic.nextMode(root.mainInstance.timerMode)
      }

      NText {
        Layout.alignment: Qt.AlignHCenter
        text: root.timeText
        family: Settings.data.ui.fontFixed
        applyUiScale: false
        pointSize: Math.round(root.fontSize * (root.timeText.length > 5 ? 0.24 : 0.32))
        font.weight: Style.fontWeightBold
        color: root.ringing ? Color.mError : Color.mOnSurface
      }

      NText {
        visible: root.mainInstance?.timerPomodoroMode ?? false
        Layout.alignment: Qt.AlignHCenter
        text: root.pluginApi?.tr(root.mainInstance?.pmPhase === "break" ? "pomodoro.break" : "pomodoro.work") ?? ""
        pointSize: Style.fontSizeS
        color: Color.mPrimary
      }

      RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Math.round(Style.marginXS * root.widgetScale)

        NIconButton {
          baseSize: Math.round(24 * root.widgetScale)
          applyUiScale: false
          icon: (root.running || root.ringing) ? "media-pause" : "media-play"
          tooltipText: root.running ? root.pluginApi?.tr("panel.pause") : root.pluginApi?.tr("panel.start")
          enabled: root.canStart
          colorBg: Color.mPrimary
          colorFg: Color.mOnPrimary
          border.width: 0
          onClicked: {
            if (root.running || root.ringing)
              root.mainInstance.timerPause();
            else
              root.mainInstance.timerStart();
          }
        }

        NIconButton {
          baseSize: Math.round(24 * root.widgetScale)
          applyUiScale: false
          icon: "refresh"
          tooltipText: root.pluginApi?.tr("panel.reset")
          enabled: root.mainInstance && (TimerLogic.isActive(root.mainInstance) || root.ringing)
          colorBg: Color.mSurfaceVariant
          colorFg: Color.mPrimary
          border.width: 0
          onClicked: root.mainInstance.timerReset()
        }
      }
    }
  }
}
