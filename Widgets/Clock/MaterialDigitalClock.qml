import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

// Digital clock: hours over minutes inside a seconds progress ring.
// The Material look (Styles/<id>/Definition.qml `views`); NClock binds its properties.
Item {
  property var now
  property color backgroundColor: ShellColors.mPrimary
  property color clockColor: ShellColors.mOnPrimary
  property color progressColor: ShellColors.mError
  property real hoursFontSize: Style.fontSizeXS
  property real minutesFontSize: Style.fontSizeXXS
  property int hoursFontWeight: Style.fontWeightBold
  property int minutesFontWeight: Style.fontWeightBold
  property real scaleRatio: Style.uiScaleRatio
  property bool showProgress: true

  anchors.fill: parent

  // Digital clock's seconds circular progress
  Canvas {
    id: secondsProgress
    anchors.fill: parent
    visible: showProgress
    property real progress: now.getSeconds() / 60
    onProgressChanged: requestPaint()
    Connections {
      target: Time
      function onNowChanged() {
        const total = now.getSeconds() * 1000 + now.getMilliseconds();
        secondsProgress.progress = total / 60000;
      }
    }
    onPaint: {
      var ctx = getContext("2d");
      var centerX = width / 2;
      var centerY = height / 2;
      var radius = Math.min(width, height) / 2 - 3 * scaleRatio;
      ctx.reset();

      // Background circle
      ctx.beginPath();
      ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);
      ctx.lineWidth = 2.5 * scaleRatio;
      ctx.strokeStyle = Qt.alpha(clockColor, 0.15);
      ctx.stroke();

      // Progress arc
      ctx.beginPath();
      ctx.arc(centerX, centerY, radius, -Math.PI / 2, -Math.PI / 2 + progress * 2 * Math.PI);
      ctx.lineWidth = 2.5 * scaleRatio;
      ctx.strokeStyle = progressColor;
      ctx.lineCap = "round";
      ctx.stroke();
    }
  }

  // Digital clock
  ColumnLayout {
    anchors.centerIn: parent
    spacing: -Style.marginXXS

    NText {
      text: {
        var t = Settings.data.location.use12hourFormat ? I18n.locale.toString(now, "hh AP") : I18n.locale.toString(now, "HH");
        return t.split(" ")[0];
      }

      pointSize: hoursFontSize
      font.weight: hoursFontWeight
      color: clockColor
      family: Style.fontFixed
      Layout.alignment: Qt.AlignHCenter
    }

    NText {
      text: Qt.formatTime(now, "mm")
      pointSize: minutesFontSize
      font.weight: minutesFontWeight
      color: clockColor
      family: Style.fontFixed
      Layout.alignment: Qt.AlignHCenter
    }
  }
}
