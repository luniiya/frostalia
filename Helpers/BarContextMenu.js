.pragma library

function entries(editing) {
  return [
    { action: "settings", labelKey: "common.settings", icon: "settings" },
    {
      action: "desktopWidgets",
      labelKey: editing ? "actions.finish-editing-desktop-widgets" : "actions.edit-desktop-widgets",
      icon: editing ? "check" : "edit"
    }
  ];
}

function toggleDesktopEditing(enabled, editing) {
  return { enabled: enabled || !editing, editing: !editing };
}

function migrateRightClickAction(action) {
  return !action || action === "none" ? "contextMenu" : action;
}
