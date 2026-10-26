#!/usr/bin/env bash
# Screenshots every shell surface in each UI style and light/dark mode, for checking
# visual changes on the running shell (see "Live testing" in CLAUDE.md).
#
# Panels are opened over IPC and captured once `qs -c frostalia ipc call state panels`
# reports them settled, so no timing has to be guessed. The original style and color
# mode are restored afterwards. Needs grim, jq and (for the contact sheets) ImageMagick.
#
# Usage: Scripts/dev/ui-screenshots.sh [-s "keycap material"] [-m "light dark"]
#                                       [-p "controlCenter launcher"] [-o DIR] [-O OUTPUT]
#   -s  UI styles to capture (default: keycap material)
#   -m  color modes to capture (default: light dark)
#   -p  shots to capture, by name from SHOTS below (default: all)
#   -o  output directory (default: $XDG_CACHE_HOME/frostalia/ui-screenshots/<time>)
#   -O  monitor to capture (default: the focused one)
#   -x  screenshot scale (default: 0.6)

set -euo pipefail

# name|ipc target|ipc function|ipc argument. "desktop", "popups" and "dock" are not panels.
# trayDrawer/trayMenu need an app in the tray drawer (kdeconnect-indicator will do); trayMenu
# right-clicks the drawer's first icon.
# A target "@Widget" clicks that bar widget instead, with the button named as the function
# (Scripts/dev/click.py; menus that only a click opens). Shots whose target is missing (a
# plugin that is not installed, a widget not on the bar) are skipped.
SHOTS=(
  "desktop|||"
  "popups|||"
  "controlCenter|controlCenter|toggle|"
  "launcher|launcher|toggle|"
  "launcherEmoji|launcher|emoji|"
  "launcherClipboard|launcher|clipboard|"
  "settings|settings|toggle|"
  "settingsTabs|||"
  "notificationHistory|notifications|toggleHistory|"
  "sessionMenu|sessionMenu|toggle|"
  "calendar|calendar|toggle|"
  "audio|volume|togglePanel|"
  "network|network|togglePanel|"
  "bluetooth|bluetooth|togglePanel|"
  "battery|battery|togglePanel|"
  "media|media|toggle|"
  "systemMonitor|systemMonitor|toggle|"
  "kdeConnect|kdeConnect|togglePanel|"
  "modelUsage|modelUsage|toggle|"
  "radialMenu|radialMenu|toggle|"
  "editDesktop|desktopWidgets|edit|"
  "workspaceOverview|plugin:workspace-overview|toggle|"
  "timer|plugin:timer|toggle|"
  "barMenus|||"
  "trayDrawer|@Tray|left|"
  "trayMenu|@Tray|left|"
  "dock|||"
)

# Settings tabs (IPC names) and how many subtabs each has; settingsTabs shoots every one
SETTINGS_TABS="general:4 userinterface:2 colorscheme:2 bar:4 bubbles:1 dock:2 desktopwidgets:1
  controlcenter:3 launcher:3 notifications:6 osd:2 sessionmenu:2 idle:2 audio:4 display:2
  connections:3 location:3 system:4 plugins:3 about:2"

styles="keycap material"
modes="light dark"
only=""
out="${XDG_CACHE_HOME:-$HOME/.cache}/frostalia/ui-screenshots/$(date +%Y%m%d-%H%M%S)"
output=""
scale="0.6"

while getopts "s:m:p:o:O:x:h" opt; do
  case $opt in
    s) styles=$OPTARG ;;
    m) modes=$OPTARG ;;
    p) only=$OPTARG ;;
    o) out=$OPTARG ;;
    O) output=$OPTARG ;;
    x) scale=$OPTARG ;;
    *) sed -n '2,17p' "$0"; exit 2 ;;
  esac
done

ipc() { qs -c frostalia ipc call "$@"; }

if [ -z "$output" ]; then
  output=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')
fi

# Polls the shell until `state panels` matches the pattern (5 s timeout)
wait_panels() {
  local pattern=$1 state=""
  for _ in $(seq 50); do
    state=$(ipc state panels 2>/dev/null || true)
    # shellcheck disable=SC2053
    [[ $state == $pattern ]] && return 0
    sleep 0.1
  done
  echo "  timed out waiting for '$pattern' (state: $state)" >&2
  return 1
}

capture() { grim -o "$output" -s "$scale" "$1"; }

click() { "$(dirname "$0")/click.py" "$@"; }
# Global position of the captured monitor's center and bottom edge, for moving the pointer
read -r mon_x mon_y mon_w mon_h < <(hyprctl monitors -j | jq -r --arg o "$output" '.[] | select(.name == $o) | "\(.x) \(.y) \(.width) \(.height)"')
center() { echo $((mon_x + mon_w / 2)) $((mon_y + mon_h / 2)); }

# Clicks on the empty desktop close a menu, then the panel under it
close_all() {
  for _ in 1 2 3; do
    [ "$(ipc state panels 2>/dev/null)" = closed ] && break
    # shellcheck disable=SC2046
    click $(center) left
    sleep 0.3
  done
  wait_panels "closed" || true
}

shoot() {
  local name=$1 target=$2 fn=$3 arg=$4 file=$5
  case $name in
    desktop)
      capture "$file"
      ;;
    popups)
      # Popups have no settled state to poll; their entry animations are short
      notify-send -a "Frostalia" -t 4000 -A ok=Okay -A later=Later "UI check" "A notification with two actions." >/dev/null 2>&1 &
      ipc toast send '{"title":"UI check","body":"A toast.","icon":"bell","duration":4000}' >/dev/null
      ipc volume increase >/dev/null
      sleep 0.8
      capture "$file"
      ipc volume decrease >/dev/null
      wait
      ;;
    settingsTabs)
      # One window, navigated tab by tab; tab switches have no settled state, so a short wait
      local tab count sub
      ipc settings openTab general >/dev/null
      wait_panels "open:settingsWindow" || return 0
      for entry in $SETTINGS_TABS; do
        tab=${entry%:*} count=${entry#*:}
        for sub in $(seq 0 $((count - 1))); do
          ipc settings openTab "$tab/$sub" >/dev/null
          sleep 0.6
          capture "${file%.png}-$tab-$sub.png"
        done
      done
      ipc settings toggle >/dev/null
      wait_panels "closed" || true
      ;;
    barMenus)
      # Right-click every widget on the bar: its context menu, or whatever it opens
      local id x y w h
      for id in $(ipc state all 2>/dev/null | jq -r '[.settings.bar.widgets[][] | .id] | unique | .[]'); do
        read -r x y w h <<<"$(ipc state widgetRect "$id" "$output")"
        [ -n "$x" ] || continue
        click $((x + w / 2)) $((y + h / 2)) right
        if wait_panels "open:*"; then
          sleep 0.3
          capture "${file%.png}-${id//[:\/]/-}.png"
        else
          echo "    $id opens nothing on right-click" >&2
        fi
        close_all
      done
      ;;
    dock)
      # The dock shows on hover at its screen edge; `dock toggle` flips the saved setting
      local was_on edge
      was_on=$(ipc state all 2>/dev/null | jq -r '.settings.dock.enabled' 2>/dev/null || echo false)
      edge=$(ipc state all 2>/dev/null | jq -r '.settings.dock.position' 2>/dev/null || echo bottom)
      [ "$was_on" = true ] || ipc dock toggle >/dev/null
      sleep 1
      case $edge in
        top) click $((mon_x + mon_w / 2)) "$mon_y" none ;;
        left) click "$mon_x" $((mon_y + mon_h / 2)) none ;;
        right) click $((mon_x + mon_w - 1)) $((mon_y + mon_h / 2)) none ;;
        *) click $((mon_x + mon_w / 2)) $((mon_y + mon_h - 1)) none ;;
      esac
      sleep 1
      capture "$file"
      # shellcheck disable=SC2046
      click $(center) none
      [ "$was_on" = true ] || ipc dock toggle >/dev/null
      sleep 0.5
      ;;
    *)
      if [[ $target == @* ]]; then
        local x y w h
        read -r x y w h <<<"$(ipc state widgetRect "${target#@}" "$output")"
        click $((x + w / 2)) $((y + h / 2)) "$fn"
        if [ "$name" = trayMenu ] && wait_panels "open:trayDrawerPanel"; then
          read -r x y w h <<<"$(ipc state trayDrawerItemRect "$output")"
          [ -n "$x" ] && click $((x + w / 2)) $((y + h / 2)) right
          wait_panels "open:popupMenu" || true
        fi
        if wait_panels "open:*"; then
          sleep 0.3
          capture "$file"
        fi
        close_all
        return
      fi
      ipc "$target" "$fn" ${arg:+"$arg"} >/dev/null
      if wait_panels "open:*"; then
        # Let images and lazily loaded content paint
        sleep 0.3
        capture "$file"
      fi
      # Toggling closes the panel again; settings tabs are closed with the window toggle
      ipc "$target" "${fn/openTab/toggle}" >/dev/null
      wait_panels "closed" || true
      ;;
  esac
}

orig_style=$(ipc uiStyle get)
orig_dark=$(ipc state all 2>/dev/null | jq -r '.settings.colorSchemes.darkMode' 2>/dev/null || echo false)
restore() {
  ipc uiStyle set "$orig_style" >/dev/null || true
  if [ "$orig_dark" = true ]; then ipc darkMode setDark >/dev/null; else ipc darkMode setLight >/dev/null; fi
}
trap restore EXIT
targets=$(qs -c frostalia ipc show 2>/dev/null | sed -n 's/^target //p')
clipboard=$(ipc state all 2>/dev/null | jq -r '.settings.appLauncher.enableClipboardHistory' 2>/dev/null || echo false)

wait_panels "closed" || { echo "Close open panels first." >&2; exit 1; }

for style in $styles; do
  ipc uiStyle set "$style" >/dev/null
  for mode in $modes; do
    if [ "$mode" = dark ]; then ipc darkMode setDark >/dev/null; else ipc darkMode setLight >/dev/null; fi
    # Color transitions and style reloads have no settled state either
    sleep 3
    dir="$out/$style-$mode"
    mkdir -p "$dir"
    echo "$style / $mode"
    for shot in "${SHOTS[@]}"; do
      IFS='|' read -r name target fn arg <<<"$shot"
      if [ -n "$only" ] && [[ " $only " != *" $name "* ]]; then
        continue
      fi
      # Clipboard mode only exists while clipboard history is on
      if [ "$name" = launcherClipboard ] && [ "$clipboard" != true ]; then
        echo "  $name skipped (clipboard history is off)"
        continue
      fi
      if [[ $target == @* ]] && [ -z "$(ipc state widgetRect "${target#@}" "$output")" ]; then
        echo "  $name skipped (no ${target#@} on the bar)"
        continue
      fi
      if [ -n "$target" ] && [[ $target != @* ]] && ! grep -qxF "$target" <<<"$targets"; then
        echo "  $name skipped (no IPC target $target)"
        continue
      fi
      echo "  $name"
      shoot "$name" "$target" "$fn" "$arg" "$dir/$name.png"
    done
    if command -v montage >/dev/null && compgen -G "$dir/*.png" >/dev/null; then
      montage -label '%t' "$dir"/*.png -tile 3x -geometry 900x+6+6 "$out/$style-$mode.png"
    fi
  done
done

echo "$out"
