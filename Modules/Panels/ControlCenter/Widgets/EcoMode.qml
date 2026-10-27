import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.Power
import qs.Widgets

// Eco (lite) mode; power saver forces it on
NIconButtonHot {
  property ShellScreen screen

  icon: "bolt"
  hot: PowerProfileService.ecoMode
  tooltipText: PowerProfileService.ecoModeForced ? I18n.tr("tooltips.eco-mode-forced") : I18n.tr("tooltips.eco-mode")
  onClicked: PowerProfileService.toggleEcoMode()
}
