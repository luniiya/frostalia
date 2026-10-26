import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "Helpers/LauncherNavigation.js" as LauncherNav
import "../../../Helpers/LauncherView.js" as LauncherView

import "Providers"
import qs.Commons
import qs.Services.Compositor
import qs.Services.Keyboard
import qs.Services.System
import qs.Services.UI
import qs.Widgets

// Launcher state, providers and keyboard handling, shared between SmartPanel
// (Launcher.qml) and the overlay (LauncherOverlayWindow.qml). The look comes
// from the per-style view loaded at the bottom of this file.
Rectangle {
  id: root
  color: "transparent"

  // External interface - set by parent
  property var screen: null
  property bool isOpen: false
  signal requestClose
  signal requestCloseImmediately

  function closeImmediately() {
    requestCloseImmediately();
  }

  // Expose for preview panel positioning
  readonly property var resultsView: view ? view.resultsView : null

  // State
  property string searchText: ""
  property int selectedIndex: 0
  property var results: []
  property var providers: []
  property var activeProvider: null
  property bool resultsReady: false
  property var pluginProviderInstances: ({})
  property bool ignoreMouseHover: true // Transient flag, should always be true on init

  // Global mouse tracking for movement detection across delegates
  property real globalLastMouseX: 0
  property real globalLastMouseY: 0
  property bool globalMouseInitialized: false
  property bool mouseTrackingReady: false // Delay tracking until panel is settled

  readonly property bool animationsDisabled: Settings.data.general.animationDisabled

  Timer {
    id: mouseTrackingDelayTimer
    interval: root.animationsDisabled ? 0 : (Style.animationNormal + 50) // Wait for panel animation to complete + safety margin
    repeat: false
    onTriggered: {
      root.mouseTrackingReady = true;
      root.globalMouseInitialized = false; // Reset so we get fresh initial position
    }
  }

  readonly property var defaultProvider: appsProvider
  readonly property var currentProvider: activeProvider || defaultProvider

  readonly property string launcherDensity: (currentProvider && currentProvider.ignoreDensity === false) ? (Settings.data.appLauncher.density || "default") : "comfortable"
  readonly property int effectiveIconSize: launcherDensity === "comfortable" ? 48 : (launcherDensity === "default" ? 36 : 24)
  readonly property int badgeSize: Math.round(effectiveIconSize * Style.uiScaleRatio)
  readonly property int entryHeight: Math.round(badgeSize + (launcherDensity === "compact" ? (Style.marginL + Style.marginXXS) : (Style.marginXL + Style.marginS)))

  readonly property bool providerShowsCategories: (currentProvider.showsCategories !== undefined ? currentProvider.showsCategories : true) && providerCategories.length > 0

  readonly property var providerCategories: {
    if (currentProvider.availableCategories && currentProvider.availableCategories.length > 0) {
      return currentProvider.availableCategories;
    }
    return currentProvider.categories || [];
  }

  readonly property bool showProviderCategories: {
    if (!providerShowsCategories || providerCategories.length === 0)
      return false;
    if (currentProvider === defaultProvider)
      return Settings.data.appLauncher.showCategories;
    return true;
  }

  readonly property bool providerHasDisplayString: results.length > 0 && !!results[0].displayString

  readonly property string providerSupportedLayouts: {
    if (activeProvider && activeProvider.supportedLayouts)
      return activeProvider.supportedLayouts;
    if (results.length > 0 && results[0].provider && results[0].provider.supportedLayouts)
      return results[0].provider.supportedLayouts;
    if (defaultProvider && defaultProvider.supportedLayouts)
      return defaultProvider.supportedLayouts;
    return "both";
  }

  readonly property bool showLayoutToggle: !providerHasDisplayString && providerSupportedLayouts === "both"

  readonly property string layoutMode: {
    if (searchText === ">")
      return "list";
    if (providerSupportedLayouts === "grid")
      return "grid";
    if (providerSupportedLayouts === "list")
      return "list";
    if (providerSupportedLayouts === "single")
      return "single";
    if (providerHasDisplayString)
      return "grid";
    return Settings.data.appLauncher.viewMode;
  }

  readonly property bool isGridView: layoutMode === "grid"
  readonly property bool isSingleView: layoutMode === "single"
  readonly property bool isCompactDensity: launcherDensity === "compact"

  readonly property int targetGridColumns: {
    let base = 5;
    if (launcherDensity === "comfortable")
      base = 4;
    else if (launcherDensity === "compact")
      base = 6;

    if (!activeProvider || activeProvider === defaultProvider)
      return base;

    if (activeProvider.preferredGridColumns) {
      let multiplier = base / 5.0;
      return Math.max(1, Math.round(activeProvider.preferredGridColumns * multiplier));
    }

    return base;
  }
  readonly property int gridColumns: targetGridColumns

  // App menu modes (apps, windows, clipboard, ...) and the query typed after
  // the mode's command prefix.
  readonly property var modes: LauncherView.availableModes(Settings.data.appLauncher.enableClipboardHistory)
  readonly property var splitSearch: LauncherView.splitQuery(searchText)
  readonly property string modeId: splitSearch.mode
  readonly property string queryText: splitSearch.query
  readonly property bool searching: searchText.trim() !== "" && (modeId === "apps" || queryText.trim() !== "")
  // Browsing the alphabetical app list: letter headings make sense.
  readonly property bool browsingApps: modeId === "apps" && searchText === "" && !isGridView
  // The best match gets a large card while searching apps in the list view.
  readonly property bool showTopHit: searchText.trim() !== "" && !activeProvider && !isGridView && results.length > 0

  readonly property int selectedCategoryIndex: showProviderCategories ? providerCategories.indexOf(currentProvider.selectedCategory) : -1
  readonly property string selectedCategoryName: selectedCategoryIndex >= 0 ? categoryName(providerCategories[selectedCategoryIndex]) : ""
  // Big title above the results.
  readonly property string headline: {
    if (searching)
      return I18n.tr("launcher.view.results");
    if (selectedCategoryName)
      return selectedCategoryName;
    return I18n.tr(LauncherView.modeById(modeId).labelKey);
  }

  readonly property var footer: LauncherView.footerState(results.length, queryText.trim(), currentProvider && currentProvider.emptyBrowsingMessage ? currentProvider.emptyBrowsingMessage : "")
  readonly property string statusText: {
    if (footer.kind === "count")
      return I18n.trp("common.result-count", footer.count);
    if (footer.kind === "empty")
      return I18n.tr("common.no-results");
    if (footer.kind === "message")
      return currentProvider.emptyBrowsingMessage;
    return "";
  }

  function setMode(id) {
    if (id === modeId)
      return;
    searchText = LauncherView.joinQuery(id, "");
    focusSearchInput();
  }

  function setQuery(text) {
    searchText = LauncherView.joinQuery(modeId, text);
  }

  function categoryIcon(category) {
    const icons = currentProvider ? currentProvider.categoryIcons : null;
    return icons ? (icons[category] || "star") : "star";
  }

  function categoryName(category) {
    return currentProvider && currentProvider.getCategoryName ? currentProvider.getCategoryName(category) : category;
  }

  function itemActions(item) {
    const provider = item ? (item.provider || currentProvider) : null;
    return provider && provider.getItemActions ? provider.getItemActions(item) : [];
  }

  function isPinned(item) {
    const provider = item ? item.provider : null;
    return !!(item && item.appId && provider && provider.isAppPinned && provider.isAppPinned({
                                                                                               "id": item.appId
                                                                                             }));
  }

  function selectIndex(index) {
    selectedIndex = index;
  }

  function activateIndex(index) {
    selectedIndex = index;
    activate();
  }

  function toggleViewMode() {
    Settings.data.appLauncher.viewMode = Settings.data.appLauncher.viewMode === "grid" ? "list" : "grid";
  }

  // App menu footer actions
  readonly property string userName: HostService.displayName
  readonly property string hostName: HostService.hostName
  readonly property string avatarPath: Settings.preprocessPath(Settings.data.general.avatarImage)

  function openSettings() {
    close();
    SettingsPanelService.openHome();
  }

  function lockSession() {
    closeImmediately();
    Qt.callLater(() => CompositorService.lock());
  }

  function openSessionMenu() {
    const s = screen;
    close();
    Qt.callLater(() => PanelService.getPanel("sessionMenuPanel", s)?.open());
  }

  // Top of the selected entry in `target` coordinates (for the preview card).
  function selectedRowTop(target) {
    return view && view.selectedRowTop ? view.selectedRowTop(target) : null;
  }

  // Check if current provider allows wrap navigation (default true)
  readonly property bool allowWrapNavigation: {
    var provider = activeProvider || currentProvider;
    return provider && provider.wrapNavigation !== undefined ? provider.wrapNavigation : true;
  }

  // Listen for plugin provider registry changes
  Connections {
    target: LauncherProviderRegistry
    function onPluginProviderRegistryUpdated() {
      root.syncPluginProviders();
    }
  }

  // Lifecycle
  onIsOpenChanged: {
    if (isOpen) {
      onOpened();
    } else {
      onClosed();
    }
  }

  onSearchTextChanged: {
    if (isOpen) {
      updateResults();
    }
  }

  function onOpened() {
    ignoreMouseHover = true;
    globalMouseInitialized = false;
    mouseTrackingReady = false;
    mouseTrackingDelayTimer.restart();

    // Show launcher immediately, results will populate asynchronously
    resultsReady = true;
    focusSearchInput();

    Qt.callLater(() => {
      syncPluginProviders();
      for (let provider of providers) {
        if (provider.onOpened)
          provider.onOpened();
      }
      updateResults();
    });
  }

  function onClosed() {
    searchText = "";
    ignoreMouseHover = true;
    if (view && view.resetVisuals)
      view.resetVisuals();
    for (let provider of providers) {
      if (provider.onClosed)
        provider.onClosed();
    }
  }

  function close() {
    requestClose();
  }

  function applyCategorySelection(tabIndex, categories) {
    const categoryList = categories || providerCategories;
    if (!categoryList || tabIndex < 0 || tabIndex >= categoryList.length)
      return false;

    currentProvider.selectCategory(categoryList[tabIndex]);
    return true;
  }

  function selectCategoryWithSlide(tabIndex) {
    if (!showProviderCategories || !currentProvider || !currentProvider.selectCategory)
      return;

    const cats = providerCategories;
    if (!cats || tabIndex < 0 || tabIndex >= cats.length)
      return;

    const currentIdx = cats.indexOf(currentProvider.selectedCategory);
    if (tabIndex === currentIdx)
      return;

    if (animationsDisabled || !view || !view.swapResults) {
      applyCategorySelection(tabIndex, cats);
      return;
    }

    const direction = tabIndex > currentIdx ? 1 : -1;
    view.swapResults(direction, () => applyCategorySelection(tabIndex, providerCategories));
  }

  // Public API
  function setSearchText(text) {
    searchText = text;
  }

  function focusSearchInput() {
    if (view && view.focusSearch)
      view.focusSearch();
  }

  // Provider registration
  function registerProvider(provider) {
    providers.push(provider);
    provider.launcher = root;
    if (provider.init)
      provider.init();
  }

  function syncPluginProviders() {
    var registeredIds = LauncherProviderRegistry.getPluginProviders();
    var changed = false;

    // Remove providers that are no longer registered
    for (var existingId in pluginProviderInstances) {
      if (registeredIds.indexOf(existingId) === -1) {
        var idx = providers.indexOf(pluginProviderInstances[existingId]);
        if (idx >= 0)
          providers.splice(idx, 1);
        delete pluginProviderInstances[existingId];
        Logger.d("Launcher", "Removed plugin provider:", existingId);
        changed = true;
      }
    }

    // Adopt persistent instances from the registry
    for (var i = 0; i < registeredIds.length; i++) {
      var providerId = registeredIds[i];
      if (!pluginProviderInstances[providerId]) {
        var instance = LauncherProviderRegistry.getProviderInstance(providerId);
        if (instance) {
          pluginProviderInstances[providerId] = instance;
          providers.push(instance);
          instance.launcher = root;
          Logger.d("Launcher", "Adopted plugin provider:", providerId);
          changed = true;
        }
      }
    }

    // Update results only if providers changed
    if (changed && root.isOpen) {
      updateResults();
    }
  }

  // Search handling
  function updateResults() {
    results = [];
    var newActiveProvider = null;

    // Check for command mode
    if (searchText.startsWith(">")) {
      for (let provider of providers) {
        if (provider.handleCommand && provider.handleCommand(searchText)) {
          newActiveProvider = provider;
          results = provider.getResults(searchText);
          break;
        }
      }

      // Show available commands if just ">" or filter commands if partial match
      if (!newActiveProvider) {
        let allCommands = [];
        for (let provider of providers) {
          if (provider.commands)
            allCommands = allCommands.concat(provider.commands());
        }
        if (searchText === ">") {
          results = allCommands;
        } else if (searchText.length > 1) {
          const query = searchText.substring(1);
          if (typeof FuzzySort !== 'undefined') {
            const fuzzyResults = FuzzySort.go(query, allCommands, {
                                                "keys": ["name"],
                                                "limit": 50
                                              });
            results = fuzzyResults.map(result => result.obj);
          } else {
            const queryLower = query.toLowerCase();
            results = allCommands.filter(cmd => (cmd.name || "").toLowerCase().includes(queryLower));
          }
        }
      }
    } else {
      // Regular search - let providers contribute results
      let allResults = [];
      for (let provider of providers) {
        if (provider.handleSearch) {
          const providerResults = provider.getResults(searchText);
          allResults = allResults.concat(providerResults);
        }
      }

      // Sort by _score (higher = better match), items without _score go first
      if (searchText.trim() !== "") {
        const boostByUsage = Settings.data.appLauncher.sortByMostUsed;

        allResults.sort((a, b) => {
          let sa = a._score !== undefined ? a._score : 0;
          let sb = b._score !== undefined ? b._score : 0;

          // Boost scores for frequently used items from tracked providers
          // _score is normalized 0–1, so boost is scaled to nudge, not overwhelm
          if (boostByUsage) {
            if (a.provider && a.provider.trackUsage && a.usageKey) {
              sa += 0.1 * Math.log2(1 + ShellState.getLauncherUsageCount(a.usageKey));
            }
            if (b.provider && b.provider.trackUsage && b.usageKey) {
              sb += 0.1 * Math.log2(1 + ShellState.getLauncherUsageCount(b.usageKey));
            }
          }

          return sb - sa;
        });
      }
      results = allResults;
    }

    // Update activeProvider only after computing new state to avoid UI flicker
    activeProvider = newActiveProvider;
    selectedIndex = 0;
  }

  // Navigation functions (delegated to LauncherNavigation.js)
  function selectNext() {
    selectedIndex = LauncherNav.selectNext(selectedIndex, results.length);
  }
  function selectPrevious() {
    selectedIndex = LauncherNav.selectPrevious(selectedIndex, results.length);
  }
  function selectNextWrapped() {
    selectedIndex = LauncherNav.selectNextWrapped(selectedIndex, results.length, allowWrapNavigation);
  }
  function selectPreviousWrapped() {
    selectedIndex = LauncherNav.selectPreviousWrapped(selectedIndex, results.length, allowWrapNavigation);
  }
  function selectFirst() {
    selectedIndex = LauncherNav.selectFirst();
  }
  function selectLast() {
    selectedIndex = LauncherNav.selectLast(results.length);
  }
  function selectNextPage() {
    selectedIndex = LauncherNav.selectNextPage(selectedIndex, results.length, entryHeight);
  }
  function selectPreviousPage() {
    selectedIndex = LauncherNav.selectPreviousPage(selectedIndex, results.length, entryHeight);
  }
  function selectPreviousRow() {
    selectedIndex = LauncherNav.selectPreviousRow(selectedIndex, results.length, gridColumns);
  }
  function selectNextRow() {
    selectedIndex = LauncherNav.selectNextRow(selectedIndex, results.length, gridColumns);
  }
  function selectPreviousColumn() {
    selectedIndex = LauncherNav.selectPreviousColumn(selectedIndex, results.length, gridColumns);
  }
  function selectNextColumn() {
    selectedIndex = LauncherNav.selectNextColumn(selectedIndex, results.length, gridColumns);
  }

  function activate() {
    if (results.length > 0 && results[selectedIndex]) {
      const item = results[selectedIndex];
      const provider = item.provider || currentProvider;

      // Track usage for providers that opt in (cross-provider "most used" tracking)
      if (Settings.data.appLauncher.sortByMostUsed && provider && provider.trackUsage && item.usageKey) {
        ShellState.recordLauncherUsage(item.usageKey);
      }

      // Check if auto-paste is enabled and provider/item supports it
      if (Settings.data.appLauncher.autoPasteClipboard && provider && provider.supportsAutoPaste && item.autoPasteText) {
        if (item.onAutoPaste)
          item.onAutoPaste();
        closeImmediately();
        Qt.callLater(() => {
          ClipboardService.pasteText(item.autoPasteText);
        });
        return;
      }

      if (item.onActivate)
        item.onActivate();
    }
  }

  function checkKey(event, settingName) {
    return Keybinds.checkKey(event, settingName, Settings);
  }

  // Keyboard handler
  function handleKeyPress(event) {
    if (checkKey(event, 'escape')) {
      close();
      event.accepted = true;
      return;
    }

    if (checkKey(event, 'enter')) {
      activate();
      event.accepted = true;
      return;
    }

    if (checkKey(event, 'up')) {
      if (!isSingleView) {
        isGridView ? selectPreviousRow() : selectPreviousWrapped();
      }
      event.accepted = true;
      return;
    }

    if (checkKey(event, 'down')) {
      if (!isSingleView) {
        isGridView ? selectNextRow() : selectNextWrapped();
      }
      event.accepted = true;
      return;
    }

    if (checkKey(event, 'left')) {
      if (isGridView) {
        selectPreviousColumn();
        event.accepted = true;
        return;
      }
    }

    if (checkKey(event, 'right')) {
      if (isGridView) {
        selectNextColumn();
        event.accepted = true;
        return;
      }
    }

    // Backspace on an empty query leaves the current mode
    if (event.key === Qt.Key_Backspace && modeId !== "apps" && queryText === "") {
      setMode("apps");
      event.accepted = true;
      return;
    }

    // Ctrl+Tab walks through the app menu modes
    if ((event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) && (event.modifiers & Qt.ControlModifier)) {
      const ids = modes.map(m => m.id);
      const step = event.key === Qt.Key_Backtab || (event.modifiers & Qt.ShiftModifier) ? -1 : 1;
      setMode(ids[LauncherView.cycleIndex(ids.indexOf(modeId), step, ids.length)]);
      event.accepted = true;
      return;
    }

    // Static bindings
    switch (event.key) {
    case Qt.Key_Tab:
      if (showProviderCategories) {
        selectCategoryWithSlide(LauncherView.cycleIndex(selectedCategoryIndex, 1, providerCategories.length));
      } else {
        selectNextWrapped();
      }
      event.accepted = true;
      break;
    case Qt.Key_Backtab:
      if (showProviderCategories) {
        selectCategoryWithSlide(LauncherView.cycleIndex(selectedCategoryIndex, -1, providerCategories.length));
      } else {
        selectPreviousWrapped();
      }
      event.accepted = true;
      break;
    case Qt.Key_Home:
      selectFirst();
      event.accepted = true;
      break;
    case Qt.Key_End:
      selectLast();
      event.accepted = true;
      break;
    case Qt.Key_PageUp:
      selectPreviousPage();
      event.accepted = true;
      break;
    case Qt.Key_PageDown:
      selectNextPage();
      event.accepted = true;
      break;
    case Qt.Key_Delete:
      if (selectedIndex >= 0 && results && results[selectedIndex]) {
        var item = results[selectedIndex];
        var provider = item.provider || currentProvider;
        if (provider && provider.canDeleteItem && provider.canDeleteItem(item))
          provider.deleteItem(item);
      }
      event.accepted = true;
      break;
    }
  }

  // -----------------------
  // Provider components
  // -----------------------
  ApplicationsProvider {
    id: appsProvider
    Component.onCompleted: {
      registerProvider(this);
      Logger.d("Launcher", "Registered: ApplicationsProvider");
    }
  }

  ClipboardProvider {
    id: clipProvider
    Component.onCompleted: {
      if (Settings.data.appLauncher.enableClipboardHistory) {
        registerProvider(this);
        Logger.d("Launcher", "Registered: ClipboardProvider");
      }
    }
  }

  CommandProvider {
    id: cmdProvider
    Component.onCompleted: {
      registerProvider(this);
      Logger.d("Launcher", "Registered: CommandProvider");
    }
  }

  EmojiProvider {
    id: emojiProvider
    Component.onCompleted: {
      registerProvider(this);
      Logger.d("Launcher", "Registered: EmojiProvider");
    }
  }

  CalculatorProvider {
    id: calcProvider
    Component.onCompleted: {
      registerProvider(this);
      Logger.d("Launcher", "Registered: CalculatorProvider");
    }
  }

  SettingsProvider {
    id: settingsProvider
    Component.onCompleted: {
      registerProvider(this);
      Logger.d("Launcher", "Registered: SettingsProvider");
    }
  }

  SessionProvider {
    id: sessionProvider
    Component.onCompleted: {
      registerProvider(this);
      Logger.d("Launcher", "Registered: SessionProvider");
    }
  }

  WindowsProvider {
    id: windowsProvider
    Component.onCompleted: {
      registerProvider(this);
      Logger.d("Launcher", "Registered: WindowsProvider");
    }
  }

  // ==================== UI Content ====================
  // The per-style view (Helpers/UiStyles.js "launcher") draws everything;
  // it reads state from and calls back into this core.

  readonly property var view: launcherView.item

  NStyleView {
    id: launcherView
    anchors.fill: parent
    surface: "launcher"
    viewProperties: ({
                       "launcher": root
                     })
    onLoaded: {
      if (root.isOpen)
        root.focusSearchInput();
    }
  }

  HoverHandler {
    id: globalHoverHandler
    enabled: !Settings.data.appLauncher.ignoreMouseInput

    onPointChanged: {
      if (!root.mouseTrackingReady) {
        return;
      }

      if (!root.globalMouseInitialized) {
        root.globalLastMouseX = point.position.x;
        root.globalLastMouseY = point.position.y;
        root.globalMouseInitialized = true;
        return;
      }

      const deltaX = Math.abs(point.position.x - root.globalLastMouseX);
      const deltaY = Math.abs(point.position.y - root.globalLastMouseY);
      if (deltaX + deltaY >= 5) {
        root.ignoreMouseHover = false;
        root.globalLastMouseX = point.position.x;
        root.globalLastMouseY = point.position.y;
      }
    }
  }
}
