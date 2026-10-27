# Frostalia – agent notes

Frostalia (github.com/luniiya/frostalia): an independent hard fork of Noctalia v4 that is diverging into its own shell. It has one maintainer and few or no outside contributors, and it does not track upstream.

Quickshell (QML) desktop shell. Entry point `shell.qml`; singletons in `Commons/` and `Services/`, UI in `Modules/` and `Widgets/`, pure JS helpers in `Helpers/`.

## Testing (required)

Every change must come with unit tests, and the full suite must pass before you report work as done.

```sh
Scripts/dev/run-tests.sh          # Rust helper tests + QML unit tests + Python repo checks
Scripts/dev/run-tests.sh -silent  # quieter; this is what the pre-commit hook runs
```

- **Rust helper tests** live in `Tools/settings/`, `Tools/theming/` and `Tools/kdeconnect/`. Run `cargo test --locked --manifest-path Tools/<helper>/Cargo.toml` for any crate; the KDE Connect integration tests need `dbus-daemon`. The test runner builds the native theming executable and sets `FROSTALIA_THEMING_HELPER` for Python integration tests.
- **QML/JS unit tests** live in `Tests/tst_*.qml` and run headless with Qt Quick Test (`qmltestrunner`). Each file is a `TestCase` with `test_*` functions; use `_data()` functions for table-driven cases.
- **Repository consistency tests** live in `Tests/python/` (stdlib `unittest`): translation keys used in QML exist in `en.json`, the settings search index is up to date, settings options match the UI.
- **Make logic testable.** QML files that import `qs.*` singletons or Quickshell types can't be loaded by `qmltestrunner`. Put non-trivial logic (geometry, parsing, state decisions) in a `.pragma library` JS file under `Helpers/` (see `Helpers/NotchGeometry.js`), call it from QML, and test the JS directly.
- When a test exposes a bug in existing code, fix it and mention it in your summary. Don't weaken the test.
- Add regression tests for bugs you fix.

## Live testing

`./install.sh` symlinks `~/.config/quickshell/frostalia` to this checkout and restarts the shell (`--no-restart`, `--copy` available). Check the log with `qs -c frostalia log`. Never `pkill -f "qs -c frostalia"`: it matches the invoking shell too. Use `qs -c frostalia kill`.

Check visual changes with screenshots of the running shell, not by reading code:

```sh
Scripts/dev/ui-screenshots.sh                         # every surface, keycap + material, light + dark
Scripts/dev/ui-screenshots.sh -s keycap -m dark -p "controlCenter launcher"
```

It opens each panel over IPC, captures it once `qs -c frostalia ipc call state panels` reports it settled (`open:<panel>` / `closed`, logic in `Helpers/PanelSettle.js`), restores the original style and color mode, and prints the output directory, which has one PNG per shot and a contact sheet per style and mode. Don't hand-roll `sleep` + `grim` sequences; add new surfaces to `SHOTS` in the script instead. For a style change, check every style, not just the one you edited. Panels on the top layer are hidden behind fullscreen windows, so leave none focused.

Surfaces that only a click opens (context menus, the tray drawer and its menus, the dock on hover) are reached with `Scripts/dev/click.py X Y [left|right|middle|none]`, a virtual uinput mouse. Get positions from IPC rather than from pixels: `state widgetRect <WidgetId> <output>` for a bar widget and `state trayDrawerItemRect <output>` for the open tray drawer (logic in `Helpers/UiProbe.js`). The tray shots need an app in the tray drawer; `kdeconnect-indicator` will do. `settingsTabs` walks every settings tab and subtab listed in `SETTINGS_TABS` (a test keeps it in sync with the tab files), and `barMenus` right-clicks every widget on the bar. The lock screen is the external lock command (hyprlock), not part of the shell.

## Working in a diverging fork

- Upstream compatibility is not a goal. Refactor, rename or delete upstream code when it makes the change cleaner; don't keep shims or dead options around for upstream parity, and don't worry about merge conflicts with upstream.
- The maintainer's own setup is the main target. Don't add compatibility layers for hypothetical other users unless asked.
- The maintainer normally commits and pushes; leave changes uncommitted unless explicitly asked to initialize or publish the repository.
- Upstream infrastructure was removed. Release and project links belong to this repository; dependency and plugin registry links retain their upstream identities.

## Conventions

- User settings are per host: `~/.config/frostalia/settings/<hostname>.toml` (path logic in `Helpers/SettingsPaths.js`). A new host is seeded once from `defaults.toml`, existing per-host JSON or legacy `settings.json`, otherwise from defaults; JSON originals are preserved. `FROSTALIA_SETTINGS_FILE` overrides the TOML path.
- Settings live in `Commons/Settings.qml` and use the Rust TOML helper (`Tools/settings/`); every new setting needs a default there. Renaming, moving or changing the meaning of a saved setting needs a migration in `Commons/Migrations/` and a bump of `settingsVersion`, so the maintainer's saved per-host settings keep working. Keep migrations small: they only need to handle configs that actually exist, not every upstream variant.

## Checklist: adding or changing a setting

Do **all** of these, every time. Missing one breaks the setting's reset button or search entry without any visible error.

1. Add or change the default in `Commons/Settings.qml`. It is the only copy: the store snapshots it before loading the host's TOML, and `Settings.getDefaultValue()`, which every reset button uses, reads that snapshot.
2. Add the UI control in `Modules/Panels/Settings/Tabs/...` with `defaultValue: Settings.getDefaultValue("section.key")`.
3. Add the label and description keys to `Assets/Translations/en.json`.
4. Run `python3 Scripts/dev/build-settings-search-index.py`.
5. If the saved value must be changed or renamed, add a migration. Changing a default only affects hosts that never saved that key.
6. Put any logic behind the setting in a `Helpers/*.js` module and add unit tests for it.
7. Run `Scripts/dev/run-tests.sh`. `Tests/python/test_settings_defaults.py` fails if a `getDefaultValue()` path has no default in `Settings.qml`, and `test_repo_consistency.py` catches missing translations and a stale search index.
- User-facing strings go through `I18n.tr("…")` with keys added to `Assets/Translations/en.json` only. Other language files are leftovers from upstream and are no longer synced; missing keys fall back to English (`Commons/I18n.qml`), so don't edit them. Removing a string may leave stale keys in them, which is fine.
- After changing settings UI, run `python3 Scripts/dev/build-settings-search-index.py`.
- `Scripts/dev/qmlfmt.sh` formats every QML file, and the pre-commit hook runs it on the whole tree. Formatter churn in files you touched is fine; don't mass-reformat unrelated files as part of a feature change.
- Match surrounding code: 2-space indent in QML/JS, comment density and naming of neighbouring code.
