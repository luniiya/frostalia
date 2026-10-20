import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services.Location
import qs.Widgets
import "../../Helpers/WeatherData.js" as WeatherData

// One weather detail (wind, UV, humidity, ...): label, big value, caption and a
// visual on the right. The content comes from WeatherData.detail().
Item {
  id: root

  property string kind: "wind"
  property real scaleFactor: 1.0

  readonly property var tile: WeatherData.detail(kind, {
                                                   "current": LocationService.currentWeather,
                                                   "today": LocationService.dailyForecast[0] || null,
                                                   "tomorrow": LocationService.dailyForecast[1] || null,
                                                   "air": LocationService.data.airQuality,
                                                   "fahrenheit": Settings.data.location.useFahrenheit,
                                                   "windUnit": Settings.data.location.windSpeedUnit,
                                                   "nowMs": Time.now.getTime(),
                                                   "formatTime": iso => I18n.locale.toString(new Date(iso), Settings.data.location.use12hourFormat ? "h:mm AP" : "HH:mm")
                                                 })
  readonly property real visualSize: Math.round(64 * Style.uiScaleRatio * scaleFactor)

  implicitWidth: Math.round(200 * Style.uiScaleRatio * scaleFactor)
  implicitHeight: Math.round(112 * Style.uiScaleRatio * scaleFactor)

  RowLayout {
    anchors.fill: parent
    spacing: Style.marginS

    ColumnLayout {
      Layout.fillWidth: true
      Layout.fillHeight: true
      spacing: 0

      RowLayout {
        spacing: Style.marginXS

        NIcon {
          icon: root.tile.icon
          pointSize: Style.fontSizeS * root.scaleFactor
          color: ShellColors.mOnSurfaceVariant
        }

        NText {
          Layout.fillWidth: true
          text: I18n.tr(root.tile.label)
          pointSize: Style.fontSizeS * root.scaleFactor
          color: ShellColors.mOnSurfaceVariant
          elide: Text.ElideRight
        }
      }

      Item {
        Layout.fillHeight: true
      }

      NText {
        Layout.fillWidth: true
        text: root.tile.valueIsKey ? I18n.tr(root.tile.value) : root.tile.value
        pointSize: (root.tile.valueIsKey ? Style.fontSizeL : Style.fontSizeXXL) * root.scaleFactor
        font.weight: Style.fontWeightMedium
        color: ShellColors.mOnSurface
        elide: Text.ElideRight
        wrapMode: Text.WordWrap
        maximumLineCount: 2
      }

      NText {
        Layout.fillWidth: true
        visible: root.tile.caption.key !== ""
        text: root.tile.caption.key !== "" ? I18n.tr(root.tile.caption.key, root.tile.caption.args) : ""
        pointSize: Style.fontSizeXS * root.scaleFactor
        color: ShellColors.mOnSurfaceVariant
        elide: Text.ElideRight
      }
    }

    Item {
      Layout.preferredWidth: root.tile.visual === "gauge" ? Math.round(root.visualSize * 0.42) : root.visualSize
      Layout.preferredHeight: root.visualSize
      Layout.alignment: Qt.AlignVCenter

      // Vertical pill gauge, filled from the bottom
      Rectangle {
        visible: root.tile.visual === "gauge"
        anchors.fill: parent
        radius: width / 2
        color: Qt.alpha(ShellColors.mOnSurface, 0.12)

        Rectangle {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          height: Math.max(parent.width, parent.height * root.tile.fraction)
          radius: parent.radius
          color: ShellColors.mPrimary

          Behavior on height {
            NumberAnimation {
              duration: Style.animationNormal
              easing.type: Easing.OutCubic
            }
          }
        }
      }

      // Cookie badge with the wind arrow or the detail icon
      Item {
        visible: root.tile.visual === "cookie"
        anchors.fill: parent

        WeatherShape {
          anchors.fill: parent
          lobes: root.kind === "uv" ? 12 : (Style.uiStyleTokens.weather ? Style.uiStyleTokens.weather.cookieLobes : 0)
          fillColor: root.kind === "uv" ? Qt.tint(ShellColors.mPrimary, Qt.alpha(ShellColors.mError, root.tile.fraction * 0.8)) : ShellColors.mPrimary
        }

        NText {
          visible: root.kind === "uv"
          anchors.centerIn: parent
          text: root.tile.value
          pointSize: Style.fontSizeL * root.scaleFactor
          font.weight: Style.fontWeightBold
          color: ShellColors.mOnPrimary
        }

        NIcon {
          visible: root.kind !== "uv"
          anchors.centerIn: parent
          icon: root.tile.icon
          rotation: root.tile.rotation
          pointSize: Style.fontSizeXL * root.scaleFactor
          color: ShellColors.mOnPrimary
        }
      }

      // Sun arc from sunrise to sunset
      Canvas {
        id: sunCanvas
        visible: root.tile.visual === "sun"
        anchors.fill: parent
        readonly property real fraction: root.tile.fraction
        onFractionChanged: requestPaint()
        onPaint: {
          const ctx = getContext("2d");
          ctx.reset();
          const line = 3 * Style.uiScaleRatio;
          const r = Math.min(width / 2, height * 0.75) - line * 2;
          const cx = width / 2;
          const cy = height * 0.8;
          ctx.lineCap = "round";
          ctx.lineWidth = line;
          ctx.strokeStyle = Qt.alpha(ShellColors.mOnSurface, 0.15);
          ctx.beginPath();
          ctx.arc(cx, cy, r, Math.PI, 2 * Math.PI);
          ctx.stroke();
          ctx.strokeStyle = ShellColors.mPrimary;
          ctx.beginPath();
          ctx.arc(cx, cy, r, Math.PI, Math.PI + Math.PI * fraction);
          ctx.stroke();
          const angle = Math.PI + Math.PI * fraction;
          ctx.fillStyle = ShellColors.mPrimary;
          ctx.beginPath();
          ctx.arc(cx + Math.cos(angle) * r, cy + Math.sin(angle) * r, line * 2, 0, 2 * Math.PI);
          ctx.fill();
          ctx.strokeStyle = Qt.alpha(ShellColors.mOnSurface, 0.3);
          ctx.lineWidth = 1;
          ctx.beginPath();
          ctx.moveTo(0, cy);
          ctx.lineTo(width, cy);
          ctx.stroke();
        }
      }

      // Moon disc lit according to the phase
      Canvas {
        visible: root.tile.visual === "moon"
        anchors.fill: parent
        readonly property real phase: root.tile.fraction
        onPhaseChanged: requestPaint()
        onPaint: {
          const ctx = getContext("2d");
          ctx.reset();
          const r = Math.min(width, height) / 2 - 2;
          const cx = width / 2;
          const cy = height / 2;
          ctx.fillStyle = Qt.alpha(ShellColors.mOnSurface, 0.15);
          ctx.beginPath();
          ctx.arc(cx, cy, r, 0, 2 * Math.PI);
          ctx.fill();
          // Lit area: outer limb on the lit side, back along the terminator
          // (k = 1 at new moon, -1 at full moon)
          const side = phase <= 0.5 ? 1 : -1;
          const k = Math.cos(phase * 2 * Math.PI);
          const steps = 48;
          ctx.fillStyle = ShellColors.mPrimary;
          ctx.beginPath();
          for (let i = 0; i <= steps; i++) {
            const t = -Math.PI / 2 + Math.PI * i / steps;
            const x = cx + side * r * Math.cos(t);
            const y = cy + r * Math.sin(t);
            if (i === 0)
              ctx.moveTo(x, y);
            else
              ctx.lineTo(x, y);
          }
          for (let i = steps; i >= 0; i--) {
            const t = -Math.PI / 2 + Math.PI * i / steps;
            ctx.lineTo(cx + side * k * r * Math.cos(t), cy + r * Math.sin(t));
          }
          ctx.closePath();
          ctx.fill();
        }
      }
    }
  }
}
