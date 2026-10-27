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
    Idle = 11,
    Launcher,
    Location,
    Connections,
    Notifications,
    Plugins,
    SessionMenu,
    System,
    UserInterface,
    Bubbles,
    RadialMenu
  }

  // -1 opens the settings home; callers set a tab before open() or toggle().
  property int requestedTab: -1
  property int requestedSubTab: -1
  property var requestedEntry: null

  // Forward the requested tab, subtab or search entry to the settings window,
  // then clear it so the next plain open goes home again.
  function openInWindow() {
    const request = SettingsWindowRequest.resolve(requestedTab, requestedSubTab, requestedEntry);
    clearRequest();
    if (request.kind === "entry")
      SettingsPanelService.openToEntry(request.entry);
    else if (request.kind === "tab")
      SettingsPanelService.openToTab(request.tab, request.subTab);
    else
      SettingsPanelService.openHome();
  }

  function clearRequest() {
    requestedTab = -1;
    requestedSubTab = -1;
    requestedEntry = null;
  }

  function toggle(buttonItem, buttonName) {
    if (SettingsPanelService.isWindowOpen) {
      clearRequest();
      SettingsPanelService.closeWindow();
    } else {
      openInWindow();
    }
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
