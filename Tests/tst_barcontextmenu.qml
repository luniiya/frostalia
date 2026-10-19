import QtQuick
import QtTest
import "../Helpers/BarContextMenu.js" as BarContextMenu

TestCase {
  name: "BarContextMenu"

  function test_menuActionsReflectEditing() {
    const normal = BarContextMenu.entries(false);
    compare(normal.map(entry => entry.action), ["settings", "desktopWidgets"]);
    compare(normal[1].labelKey, "actions.edit-desktop-widgets");
    compare(normal[1].icon, "edit");
    const editing = BarContextMenu.entries(true);
    compare(editing[1].labelKey, "actions.finish-editing-desktop-widgets");
    compare(editing[1].icon, "check");
    normal[0].action = "modified";
    compare(BarContextMenu.entries(false)[0].action, "settings");
  }

  function test_toggleDesktopEditing_data() {
    return [
          {
            tag: "enable widgets before editing",
            enabled: false,
            editing: false,
            nextEnabled: true,
            nextEditing: true
          },
          {
            tag: "edit enabled widgets",
            enabled: true,
            editing: false,
            nextEnabled: true,
            nextEditing: true
          },
          {
            tag: "finish editing keeps widgets enabled",
            enabled: true,
            editing: true,
            nextEnabled: true,
            nextEditing: false
          },
          {
            tag: "finish editing after widgets disabled",
            enabled: false,
            editing: true,
            nextEnabled: false,
            nextEditing: false
          }
        ];
  }

  function test_toggleDesktopEditing(data) {
    compare(BarContextMenu.toggleDesktopEditing(data.enabled, data.editing), {
              enabled: data.nextEnabled,
              editing: data.nextEditing
            });
  }

  function test_migrateDefault_data() {
    return [
          {
            tag: "missing",
            before: undefined,
            after: "contextMenu"
          },
          {
            tag: "old default",
            before: "none",
            after: "contextMenu"
          },
          {
            tag: "already migrated",
            before: "contextMenu",
            after: "contextMenu"
          },
          {
            tag: "custom command",
            before: "command",
            after: "command"
          },
          {
            tag: "control center",
            before: "controlCenter",
            after: "controlCenter"
          },
          {
            tag: "direct settings",
            before: "settings",
            after: "settings"
          }
        ];
  }

  function test_migrateDefault(data) {
    compare(BarContextMenu.migrateRightClickAction(data.before), data.after);
  }
}
