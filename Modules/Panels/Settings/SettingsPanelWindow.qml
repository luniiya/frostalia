import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../../Helpers/SettingsWindowLayout.js" as SettingsWindowLayout
import qs.Commons
import qs.Services.UI
import qs.Widgets

FloatingWindow {
  id: root

  title: "Frostalia"
  readonly property var windowMetrics: SettingsWindowLayout.windowMetrics(Style.materialControls, Style.uiScaleRatio)
  minimumSize: Qt.size(windowMetrics.minimumWidth, windowMetrics.minimumHeight)
  implicitWidth: windowMetrics.width
  implicitHeight: windowMetrics.height
  // Paint the window surface itself, so the compositor's corner rounding is the only one
  color: Qt.alpha(ShellColors.mSurface, Style.panelOpacity)

  // Ask the compositor to blur behind the whole window; without a region it
  // shows the translucent background unblurred.
  BackgroundEffect.blurRegion: Settings.data.general.enableBlurBehind ? windowBlurRegion : null
  Region {
    id: windowBlurRegion
    width: root.width
    height: root.height
  }

  visible: false

  // Register with SettingsPanelService
  Component.onCompleted: {
    SettingsPanelService.settingsWindow = root;
  }

  property bool isInitialized: false

  function navigateHome() {
    if (!isInitialized) {
      settingsContent.requestedTab = SettingsPanel.Tab.General;
      settingsContent._pendingSubTab = -1;
      settingsContent.initialize();
      isInitialized = true;
    }
    settingsContent.showHome();
  }

  // Navigate to a specific tab and optional subtab.
  // Works whether the window is already visible or just becoming visible.
  function navigateTo(tab, subTab) {
    const tabId = tab !== undefined ? tab : 0;
    const subTabId = (subTab !== undefined && subTab !== null && subTab >= 0) ? subTab : -1;
    if (isInitialized) {
      settingsContent.navigateToTab(tabId, subTabId);
    } else {
      settingsContent.requestedTab = tabId;
      if (subTabId >= 0)
        settingsContent._pendingSubTab = subTabId;
      settingsContent.initialize();
      isInitialized = true;
      // Tab content persists in window mode; if no subtab specified and the
      // tab content is still loaded (same tab), reset to first subtab
      if (subTabId < 0 && settingsContent.activeTabContent)
        settingsContent.setSubTabIndex(0);
    }
  }

  // Navigate to a search result entry.
  // Works whether the window is already visible or just becoming visible.
  function navigateToEntry(entry) {
    if (isInitialized) {
      Qt.callLater(() => settingsContent.navigateToResult(entry));
    } else {
      settingsContent.requestedTab = entry.tab;
      settingsContent.initialize();
      Qt.callLater(() => settingsContent.navigateToResult(entry));
      isInitialized = true;
    }
  }

  // Sync visibility with service
  onVisibleChanged: {
    if (visible) {
      SettingsPanelService.isWindowOpen = true;
    } else {
      isInitialized = false;
      SettingsPanelService.isWindowOpen = false;
    }
  }

  // Keyboard shortcuts
  Shortcut {
    sequence: "Escape"
    enabled: !PanelService.isKeybindRecording
    onActivated: settingsContent.handleEscape()
  }

  Shortcut {
    sequence: "Tab"
    enabled: !PanelService.isKeybindRecording
    onActivated: settingsContent.selectNextTab()
  }

  Shortcut {
    sequence: "Backtab"
    enabled: !PanelService.isKeybindRecording
    onActivated: settingsContent.selectPreviousTab()
  }

  Instantiator {
    model: Settings.data.general.keybinds.keyUp || []
    Shortcut {
      sequence: modelData
      enabled: !PanelService.isKeybindRecording
      onActivated: {
        if (settingsContent.searchText.trim() !== "")
          settingsContent.searchSelectPrevious();
        else
          settingsContent.scrollUp();
      }
    }
  }

  Instantiator {
    model: Settings.data.general.keybinds.keyDown || []
    Shortcut {
      sequence: modelData
      enabled: !PanelService.isKeybindRecording
      onActivated: {
        if (settingsContent.searchText.trim() !== "")
          settingsContent.searchSelectNext();
        else
          settingsContent.scrollDown();
      }
    }
  }

  // Main content
  SettingsContent {
    id: settingsContent
    anchors.fill: parent
    onCloseRequested: SettingsPanelService.closeWindow()
  }
}
