# Frostalia – agent notes

Frostalia (github.com/luniiya/frostalia): an independent hard fork of Noctalia v4 that is diverging into its own shell. It has one maintainer and few or no outside contributors, and it does not track upstream.

Quickshell (QML) desktop shell. Entry point `shell.qml`; singletons in `Commons/` and `Services/`, UI in `Modules/` and `Widgets/`, pure JS helpers in `Helpers/`.

## Testing (required)

Every change must come with unit tests, and the full suite must pass before you report work as done.

```sh
Scripts/dev/run-tests.sh          # Rust helper tests + QML unit tests + Python repo checks
Scripts/dev/run-tests.sh -silent  # quieter; this is what the pre-commit hook runs
```

- **Rust settings helper tests** live in `Tools/settings/` and run with `cargo test --locked --manifest-path Tools/settings/Cargo.toml`.
- **QML/JS unit tests** live in `Tests/tst_*.qml` and run headless with Qt Quick Test (`qmltestrunner`). Each file is a `TestCase` with `test_*` functions; use `_data()` functions for table-driven cases.
- **Repository consistency tests** live in `Tests/python/` (stdlib `unittest`): translation keys used in QML exist in `en.json`, the settings search index is up to date, settings options match the UI.
- **Make logic testable.** QML files that import `qs.*` singletons or Quickshell types can't be loaded by `qmltestrunner`. Put non-trivial logic (geometry, parsing, state decisions) in a `.pragma library` JS file under `Helpers/` (see `Helpers/NotchGeometry.js`), call it from QML, and test the JS directly.
- When a test exposes a bug in existing code, fix it and mention it in your summary. Don't weaken the test.
- Add regression tests for bugs you fix.

## Live testing

`./install.sh` symlinks `~/.config/quickshell/frostalia` to this checkout and restarts the shell (`--no-restart`, `--copy` available). Check the log with `qs -c frostalia log`. Never `pkill -f "qs -c frostalia"`: it matches the invoking shell too. Use `qs -c frostalia kill`.

## Working in a diverging fork

- Upstream compatibility is not a goal. Refactor, rename or delete upstream code when it makes the change cleaner; don't keep shims or dead options around for upstream parity, and don't worry about merge conflicts with upstream.
- The maintainer's own setup is the main target. Don't add compatibility layers for hypothetical other users unless asked.
- The maintainer normally commits and pushes; leave changes uncommitted unless explicitly asked to initialize or publish the repository.
- Upstream infrastructure was removed. Release and project links belong to this repository; dependency and plugin registry links retain their upstream identities.

## Conventions

- User settings are per host: `~/.config/frostalia/settings/<hostname>.toml` (path logic in `Helpers/SettingsPaths.js`). A new host is seeded once from `settings.toml`, existing per-host JSON or legacy `settings.json`, otherwise from defaults; JSON originals are preserved. `FROSTALIA_SETTINGS_FILE` overrides the TOML path.
- Settings live in `Commons/Settings.qml` and use the Rust TOML helper (`Tools/settings/`); every new setting needs a default there. Renaming, moving or changing the meaning of a saved setting needs a migration in `Commons/Migrations/` and a bump of `settingsVersion`, so the maintainer's saved per-host settings keep working. Keep migrations small: they only need to handle configs that actually exist, not every upstream variant.

## Checklist: adding or changing a setting

Do **all** of these, every time. Missing one breaks the setting's reset button or search entry without any visible error.

1. Add or change the default in `Commons/Settings.qml`.
2. Add or change **the same value** in `Assets/settings-default.json`. It backs `Settings.getDefaultValue()`, which every reset button uses.
3. Add the UI control in `Modules/Panels/Settings/Tabs/...` with `defaultValue: Settings.getDefaultValue("section.key")`.
4. Add the label and description keys to `Assets/Translations/en.json`.
5. Run `python3 Scripts/dev/build-settings-search-index.py`.
6. If the saved value must be changed or renamed, add a migration. Changing a default only affects hosts that never saved that key.
7. Put any logic behind the setting in a `Helpers/*.js` module and add unit tests for it.
8. Run `Scripts/dev/run-tests.sh`. `Tests/python/test_settings_defaults.py` fails if steps 1 and 2 disagree, and `test_repo_consistency.py` catches missing translations and a stale search index.
- User-facing strings go through `I18n.tr("…")` with keys added to `Assets/Translations/en.json` only. Other language files are leftovers from upstream and are no longer synced; missing keys fall back to English (`Commons/I18n.qml`), so don't edit them. Removing a string may leave stale keys in them, which is fine.
- After changing settings UI, run `python3 Scripts/dev/build-settings-search-index.py`.
- `Scripts/dev/qmlfmt.sh` formats every QML file, and the pre-commit hook runs it on the whole tree. Formatter churn in files you touched is fine; don't mass-reformat unrelated files as part of a feature change.
- Match surrounding code: 2-space indent in QML/JS, comment density and naming of neighbouring code.
