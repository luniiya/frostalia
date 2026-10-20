import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Modules.Panels.Settings
import qs.Services.UI
import qs.Widgets

Item {
  id: root
  property var screen
  property string uptime: "--"
  implicitHeight: Math.round(48 * Style.uiScaleRatio)

  // Control Center sub-tabs: Appearance, Cards, Shortcuts.
  readonly property int shortcutsSubTab: 2

  function openSettings(tab, subTab) {
    PanelService.getPanel("controlCenterPanel", screen)?.close();
    SettingsPanelService.openToTab(tab, subTab);
  }

  RowLayout {
    anchors.fill: parent
    spacing: Style.marginS
    NPill {
      Layout.fillHeight: true
      spacing: Style.marginS
      NIcon {
        icon: "clock"
        pointSize: Style.fontSizeL
        color: ShellColors.mOnSurfaceVariant
      }
      NText {
        text: I18n.tr("system.uptime", {
                        uptime: root.uptime
                      })
        pointSize: Style.fontSizeS
      }
    }
    Item {
      Layout.fillWidth: true
    }
    NPill {
      Layout.fillHeight: true
      NIconButton {
        icon: "pencil"
        baseSize: Style.baseWidgetSize
        tooltipText: I18n.tr("control-center.edit-shortcuts")
        onClicked: root.openSettings(SettingsPanel.Tab.ControlCenter, root.shortcutsSubTab)
      }
      NIconButton {
        icon: "settings"
        baseSize: Style.baseWidgetSize
        tooltipText: I18n.tr("tooltips.open-settings")
        onClicked: {
          PanelService.getPanel("controlCenterPanel", root.screen)?.close();
          SettingsPanelService.openHome();
        }
      }
      NIconButton {
        icon: "power"
        baseSize: Style.baseWidgetSize
        tooltipText: I18n.tr("tooltips.session-menu")
        onClicked: {
          PanelService.getPanel("controlCenterPanel", root.screen)?.close();
          PanelService.getPanel("sessionMenuPanel", root.screen)?.open();
        }
      }
    }
  }
  Process {
    id: uptimeProcess
    command: ["cat", "/proc/uptime"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: root.uptime = Time.formatVagueHumanReadableDuration(parseFloat(text.split(" ")[0]))
    }
  }
  Timer {
    interval: 60000
    repeat: true
    running: true
    onTriggered: uptimeProcess.running = true
  }
}
