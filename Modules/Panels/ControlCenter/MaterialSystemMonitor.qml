import QtQuick
import QtQuick.Layouts
import "../../../Helpers/ControlCenterLayout.js" as ControlCenterLayout
import qs.Commons
import qs.Services.System
import qs.Widgets

Rectangle {
  id: root
  implicitHeight: Math.round(76 * Style.uiScaleRatio)
  radius: Style.radiusM
  color: ShellColors.mSurfaceVariant
  readonly property string disk: Settings.data.controlCenter.diskPath || "/"
  Component.onCompleted: SystemStatService.registerComponent("material-control-center")
  Component.onDestruction: SystemStatService.unregisterComponent("material-control-center")

  NStyleCard {}

  RowLayout {
    id: stats
    anchors.fill: parent
    anchors.margins: Style.marginM
    spacing: Style.marginS
    Repeater {
      id: statsRepeater
      model: [
        {
          icon: "cpu-usage",
          label: I18n.tr("system-monitor.cpu-usage"),
          value: Math.round(SystemStatService.cpuUsage) + "%"
        },
        {
          icon: "cpu-temperature",
          label: I18n.tr("system-monitor.cpu-temp"),
          value: Math.round(SystemStatService.cpuTemp) + "°C"
        },
        {
          icon: "memory",
          label: I18n.tr("common.memory"),
          value: Math.round(SystemStatService.memPercent) + "%"
        },
        {
          icon: "storage",
          label: I18n.tr("system-monitor.disk"),
          value: Math.round(SystemStatService.diskPercents[root.disk] || 0) + "%"
        }
      ]
      ColumnLayout {
        required property var modelData
        // Equal columns, so long labels don't widen their stat.
        readonly property real cellWidth: ControlCenterLayout.equalWidth(stats.width, stats.spacing, statsRepeater.count)
        Layout.minimumWidth: cellWidth
        Layout.preferredWidth: cellWidth
        Layout.maximumWidth: cellWidth
        spacing: Style.marginXXS
        NIcon {
          Layout.alignment: Qt.AlignHCenter
          icon: modelData.icon
          color: ShellColors.mPrimary
          pointSize: Style.fontSizeL
        }
        NText {
          Layout.fillWidth: true
          horizontalAlignment: Text.AlignHCenter
          text: modelData.value
          pointSize: Style.fontSizeS
        }
        NText {
          Layout.fillWidth: true
          horizontalAlignment: Text.AlignHCenter
          text: modelData.label
          color: ShellColors.mOnSurfaceVariant
          pointSize: Style.fontSizeXXS
          elide: Text.ElideRight
        }
      }
    }
  }
}
