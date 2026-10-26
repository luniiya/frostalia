# TODO

## Leftovers from removing Caelestia
- `~/.config/frostalia/settings/UI/caelestia.toml` (saved Caelestia appearance) is no longer read; delete it by hand.

## Keycap style: feels buggy and untested
- Check it with `Scripts/dev/ui-screenshots.sh` (both styles, light and dark).
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
