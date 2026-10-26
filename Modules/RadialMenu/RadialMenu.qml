import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../Helpers/BarContextMenu.js" as BarContextMenu
import qs.Commons
import qs.Modules.Panels.Settings
import qs.Services.Compositor
import qs.Services.UI

// Fly-Pie style radial menu on the empty desktop. A transparent background-layer
// surface catches the right click (desktop widgets sit above it on the bottom layer and
// keep their own clicks); the menu itself is an overlay window on that screen. Holding
// the button and flicking towards an item picks it; a plain right click leaves the menu
// open for hover and click.
Scope {
  id: root

  // Right click catcher, one per screen
  Variants {
    model: Quickshell.screens

    delegate: Loader {
      id: catcherLoader
      required property ShellScreen modelData
      active: Settings.data.radialMenu.enabled

      sourceComponent: PanelWindow {
        screen: catcherLoader.modelData
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "frostalia-desktop-menu-catcher-" + (screen?.name || "unknown")

        anchors {
          top: true
          bottom: true
          left: true
          right: true
        }

        MouseArea {
          anchors.fill: parent
          acceptedButtons: Qt.RightButton
          // The Edit Desktop screen handles its own clicks (right click there selects a widget)
          enabled: !DesktopWidgetRegistry.editMode

          onPressed: mouse => RadialMenuService.openAt(catcherLoader.modelData, mouse.x, mouse.y)
          // The press grab stays here while the menu window is shown: feed the stroke through
          onPositionChanged: mouse => RadialMenuService.pointerMoved(mouse.x, mouse.y)
          onReleased: mouse => RadialMenuService.pointerReleased(mouse.x, mouse.y)
        }
      }
    }
  }

  // The menu, only on the screen it was opened on
  Variants {
    model: Quickshell.screens

    delegate: Loader {
      id: menuLoader
      required property ShellScreen modelData
      active: RadialMenuService.shown && RadialMenuService.screenName === modelData.name

      sourceComponent: RadialMenuWindow {
        screen: menuLoader.modelData
      }
    }
  }

  // Close when the editor opens from elsewhere or the feature is turned off
  Connections {
    target: DesktopWidgetRegistry
    function onEditModeChanged() {
      if (DesktopWidgetRegistry.editMode)
        RadialMenuService.close();
    }
  }

  Connections {
    target: RadialMenuService
    function onActivated(item, screen) {
      root.run(item, screen);
    }
  }

  // Item actions, reusing what the bar menu and the IPC handlers call
  function run(item, screen) {
    Logger.d("RadialMenu", "Run", item.action, item.arg);
    switch (item.action) {
    case "editDesktop":
    {
      const next = BarContextMenu.toggleDesktopEditing(Settings.data.desktopWidgets.enabled, DesktopWidgetRegistry.editMode);
      Settings.data.desktopWidgets.enabled = next.enabled;
      DesktopWidgetRegistry.editMode = next.editing;
      break;
    }
    case "settings":
      SettingsPanelService.openHome();
      break;
    case "wallpaper":
      // Wallpapers belong to the system daemon (awww/hyprpaper). Without a picker
      // command, open the wallpaper color settings.
      if (item.arg)
        Quickshell.execDetached(["sh", "-c", item.arg]);
      else
        SettingsPanelService.openToTab(SettingsPanel.Tab.ColorScheme, -1, screen);
      break;
    case "lock":
      CompositorService.lock();
      break;
    case "sessionMenu":
      PanelService.getPanel("sessionMenuPanel", screen)?.toggle();
      break;
    case "launcher":
      PanelService.openLauncherWithSearch(screen, "");
      break;
    case "controlCenter":
      PanelService.getPanel("controlCenterPanel", screen)?.toggle();
      break;
    case "app":
      launchApp(item.arg);
      break;
    case "command":
      if (item.arg)
        Quickshell.execDetached(["sh", "-c", item.arg]);
      break;
    }
  }

  // Same launch rules as the dock's pinned apps
  function launchApp(appId) {
    const app = appId ? ThemeIcons.findAppEntry(appId) : null;
    if (!app) {
      Logger.w("RadialMenu", "No desktop entry for", appId);
      return;
    }
    const launcher = Settings.data.appLauncher;
    const terminal = app.runInTerminal && launcher.terminalCommand.trim() !== "" ? launcher.terminalCommand.trim().split(" ") : [];
    if (launcher.customLaunchPrefixEnabled && launcher.customLaunchPrefix.trim() !== "")
      Quickshell.execDetached(launcher.customLaunchPrefix.trim().split(" ").concat(terminal, app.command));
    else if (terminal.length > 0)
      CompositorService.spawn(terminal.concat(app.command));
    else if (app.command && app.command.length > 0)
      CompositorService.spawn(app.command);
    else if (app.execute)
      app.execute();
  }
}
