# TODO

## Remove the Caelestia UI style
- Delete the style completely: `Helpers/UiStyles.js` entry, `Modules/Panels/ControlCenter/CaelestiaControlCenter.qml`, `CaelestiaKdeConnectCard.qml`, `Modules/Panels/KdeConnect/CaelestiaKdeConnectHome.qml`, the Caelestia branches in `Commons/Style.qml`, `Widgets/NAvatar.qml`, `Widgets/NCollapsible.qml`, `Modules/Weather/WeatherSurface.qml`, `Helpers/RadialMenu.js` (orbit shape), the README, and the Rust fixtures in `Tools/settings/tests/ui_profiles.rs`.
- Update every test that mentions it (`Tests/tst_ui*.qml`, `tst_stylefonts`, `tst_controlcenterlayout`, `tst_settingswindowlayout`, `tst_keycapstyle`, `tst_radialmenu`, `Tests/python/test_ui_styles.py`, `test_style_views.py`, `test_keycap_style.py`, `test_settings_store.py`, `test_kdeconnect.py`, `test_weather_widgets.py`, `Tests/integration/ui-style-store.qml`).
- Needs a migration in `Commons/Migrations/` plus a `settingsVersion` bump (now 75): saved `caelestia` becomes `material` (or `keycap`). Check the saved value in `~/.config/frostalia/settings/*.toml` first.
- Keycap panels currently reuse the Caelestia layouts, so Keycap needs its own panel layouts first (control center, settings window, launcher, notifications, media panel) or it falls back to the Material ones. Also give Keycap its own panel pop-in animations.

## Keycap style: feels buggy and untested
- It was never run on the live shell. Go through it by hand: bar widgets, controls, panels, radial menu.
- Watch for: plugins that set `pressed` on `NIconButton` or the bar pill, cramped or clipped 2 px hard shadows (mini bar, clipped lists), launcher and control-center custom icons that don't sink, grouped workspaces missing per-workspace keys.
- Google Sans Flex isn't installed (it falls back to Google Sans, then Rubik). Check the licence before installing; installer source `github.com/end-4/google-sans-flex`.

## Desktop radial menu: not tested live
- Right-click on empty desktop, hold-and-flick, Esc, Backspace, keys 1-9, and every default action.
- If right-click does nothing, the click-catcher layer may sit below the wallpaper daemon's surface.
- The Wallpaper item has no picker (runs its `arg` command or opens the colour scheme tab).

## Edit Desktop: not tested by hand
- Drag from the shelf, move, resize and scale handles, actions bar (settings, reset, raise, lower, delete), undo/redo, Esc, Delete key.
- Timer plugin tile has no live preview; AudioVisualizer preview is empty without audio.
- `Binding loop detected for property "y"` warning from `Modules/EditDesktop/EditShelf.qml` (may be stale).
- Bar stand-in on the card is hardly visible.
- Add unit tests for the shelf helpers.
- Later rounds: presets, tabs, lyrics widget.

## Notch panel snap
- Control-center top gap fix (`snapToBarEnds` now also snaps from the screen edge up to inset + radius) was only unit tested. Open the control center and check the top.

## Housekeeping
- Nothing from this session is committed. No Co-Authored-By lines on commits.
