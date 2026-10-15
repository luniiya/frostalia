import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.Power
import qs.Widgets

NIconButtonHot {
  property ShellScreen screen

  icon: PowerProfileService.frostaliaPerformanceMode ? "rocket" : "rocket-off"
  tooltipText: I18n.tr("tooltips.frostalia-performance-enabled")
  hot: PowerProfileService.frostaliaPerformanceMode
  onClicked: PowerProfileService.toggleFrostaliaPerformance()
}
