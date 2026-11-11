import QtQuick
import QtQuick.Layouts
import Quickshell
import "../Helpers/ColorsConvert.js" as ColorsConvert
import qs.Commons
import qs.Widgets

Item {
  id: root

  property var now: Time.now

  // Style: "analog" or "digital"
  property string clockStyle: "analog"

  // Show seconds progress ring (digital only)
  property bool showProgress: true

  // Color properties
  property color backgroundColor: ShellColors.mPrimary
  property color clockColor: ShellColors.mOnPrimary

  property color secondHandColor: {
    var defaultColor = ShellColors.mError;
    var bestContrast = 1.0; // 1.0 is "no contrast"
    var bestColor = defaultColor;
    var candidates = [ShellColors.mSecondary, ShellColors.mTertiary, ShellColors.mError];

    const minContrast = 1.149;

    for (var i = 0; i < candidates.length; i++) {
      var candidate = candidates[i];
      var contrastClock = ColorsConvert.getContrastRatio(candidate.toString(), clockColor.toString());
      if (contrastClock < minContrast) {
        continue;
      }
      var contrastBg = ColorsConvert.getContrastRatio(candidate.toString(), backgroundColor.toString());
      if (contrastBg < minContrast) {
        continue;
      }

      var currentWorstContrast = Math.min(contrastBg, contrastClock);

      if (currentWorstContrast > bestContrast) {
        bestContrast = currentWorstContrast;
        bestColor = candidate;
      }
    }

    return bestColor;
  }

  property color progressColor: root.secondHandColor

  // Font size properties for digital clock
  property real hoursFontSize: Style.fontSizeXS
  property real minutesFontSize: Style.fontSizeXXS
  property int hoursFontWeight: Style.fontWeightBold
  property int minutesFontWeight: Style.fontWeightBold

  // Scale ratio for canvas line widths (used by desktop widget scaling)
  property real scaleRatio: Style.uiScaleRatio

  height: Math.round((Style.fontSizeXXXL * 1.9) / 2 * Style.uiScaleRatio) * 2
  width: root.height

  Loader {
    id: clockLoader
    anchors.fill: parent

    // The active style's clock face (Styles/<id>/Definition.qml `views`)
    source: Style.surfaceUrl(root.clockStyle === "analog" ? "clockAnalog" : root.clockStyle === "binary" ? "clockBinary" : "clockDigital")

    onLoaded: {
      item.now = Qt.binding(function () {
        return root.now;
      });
      item.backgroundColor = Qt.binding(function () {
        return root.backgroundColor;
      });
      item.clockColor = Qt.binding(function () {
        return root.clockColor;
      });
      if (item.hasOwnProperty("secondHandColor")) {
        item.secondHandColor = Qt.binding(function () {
          return root.secondHandColor;
        });
      }
      if (item.hasOwnProperty("progressColor")) {
        item.progressColor = Qt.binding(function () {
          return root.progressColor;
        });
      }
      if (item.hasOwnProperty("hoursFontSize")) {
        item.hoursFontSize = Qt.binding(function () {
          return root.hoursFontSize;
        });
      }
      if (item.hasOwnProperty("minutesFontSize")) {
        item.minutesFontSize = Qt.binding(function () {
          return root.minutesFontSize;
        });
      }
      if ("hoursFontWeight" in item) {
        item.hoursFontWeight = Qt.binding(function () {
          return root.hoursFontWeight;
        });
      }
      if ("minutesFontWeight" in item) {
        item.minutesFontWeight = Qt.binding(function () {
          return root.minutesFontWeight;
        });
      }
      if (item.hasOwnProperty("scaleRatio")) {
        item.scaleRatio = Qt.binding(function () {
          return root.scaleRatio;
        });
      }
      if ("showProgress" in item) {
        item.showProgress = Qt.binding(function () {
          return root.showProgress;
        });
      }
    }
  }
}
