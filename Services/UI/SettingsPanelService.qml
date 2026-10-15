pragma Singleton

import QtQuick
import Quickshell
import qs.Commons
import qs.Services.UI

Singleton {
  id: root

  // Track if the settings window is open
  property bool isWindowOpen: false

  // Reference to the window (set by SettingsPanelWindow)
  property var settingsWindow: null

  // Requested tab when opening
  property int requestedTab: 0

  // Requested subtab when opening (-1 means no specific subtab)
  property int requestedSubTab: -1

  // Requested entry for search navigation
  property var requestedEntry: null

  signal windowOpened
  signal windowClosed

  // Settings always open in their own window. The screen parameters are kept
  // for API compatibility with callers and plugins and are ignored.
  function openToEntry(entry, screen) {
    requestedEntry = entry;
    if (settingsWindow) {
      settingsWindow.visible = true;
      isWindowOpen = true;
      windowOpened();
      settingsWindow.navigateToEntry(entry);
    }
  }

  // Open settings to a specific tab and subtab
  function openToTab(tab, subTab, screen) {
    const tabId = tab !== undefined ? tab : 0;
    const subTabId = subTab !== undefined ? subTab : -1;
    requestedTab = tabId;
    requestedSubTab = subTabId;
    if (settingsWindow) {
      settingsWindow.visible = true;
      isWindowOpen = true;
      windowOpened();
      settingsWindow.navigateTo(tabId, subTabId);
    }
  }

  function openWindow(tab) {
    openToTab(tab, -1);
  }

  function closeWindow() {
    if (settingsWindow) {
      settingsWindow.visible = false;
      isWindowOpen = false;
      windowClosed();
    }
  }

  function toggleWindow(tab) {
    if (isWindowOpen) {
      closeWindow();
    } else {
      openWindow(tab);
    }
  }

  // Opens to tab/subtab if closed, closes if open
  function toggle(tab, subTab, screen) {
    if (isWindowOpen) {
      closeWindow();
    } else {
      openToTab(tab, subTab);
    }
  }

  function close(screen) {
    closeWindow();
  }
}
