import QtQuick
import Quickshell
import "../../../Helpers/SettingsWindowRequest.js" as SettingsWindowRequest
import qs.Commons
import qs.Modules.MainScreen
import qs.Services.UI

// Settings always open in their own compositor window (SettingsPanelWindow).
// This panel is never shown; it stays registered as "settingsPanel" so existing
// callers and plugins can keep using PanelService.getPanel("settingsPanel", screen).
SmartPanel {
  id: root

  // Tabs enumeration, order is NOT relevant
  enum Tab {
    About,
    Audio,
    Bar,
    ColorScheme,
    ControlCenter,
    DesktopWidgets,
    OSD,
    Display,
    Dock,
    General,
    Hooks,
    Idle,
    Launcher,
    Location,
    Connections,
    Notifications,
    Plugins,
    SessionMenu,
    System,
    UserInterface,
    Bubbles
  }

  property int requestedTab: SettingsPanel.Tab.General
  property int requestedSubTab: -1
  property var requestedEntry: null

  // Forward the requested tab, subtab or search entry to the settings window
  function openInWindow() {
    const request = SettingsWindowRequest.resolve(requestedTab, requestedSubTab, requestedEntry);
    requestedSubTab = -1;
    requestedEntry = null;
    if (request.kind === "entry")
      SettingsPanelService.openToEntry(request.entry);
    else
      SettingsPanelService.openToTab(request.tab, request.subTab);
  }

  function toggle(buttonItem, buttonName) {
    if (SettingsPanelService.isWindowOpen)
      SettingsPanelService.closeWindow();
    else
      openInWindow();
  }

  function open(buttonItem, buttonName) {
    openInWindow();
  }

  // Open to a specific tab and optionally a subtab
  function openToTab(tab, subTab, buttonItem, buttonName) {
    requestedTab = tab !== undefined ? tab : SettingsPanel.Tab.General;
    requestedSubTab = subTab !== undefined ? subTab : -1;
    openInWindow();
  }
}
