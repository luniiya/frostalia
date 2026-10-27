#!/bin/bash
# A test environment that leaves the real desktop alone: a nested Hyprland running
# this checkout's shell, its window kept on workspace 100 in the background by the
# "frostalia-test-env" window rule in ~/.config/hypr/shared/frostalia-test-env.lua.
# Screenshots come from the nested compositor and clicks go to its own virtual
# pointer (Scripts/dev/test_env_pointer.py), so the real screen, cursor and focus
# never change. The shell runs on a copy of the real settings and cache and on a
# private D-Bus session, so it can't overwrite settings or take over notifications,
# the tray or media keys (it doesn't see MPRIS players either).
#
# The nested Hyprland loads the real look-and-feel and input files from ~/.config/hypr/shared
# (not autostart, bindings or monitors, which would start a second copy of the real apps), shows
# the real wallpaper through its own awww-daemon, and the settings copy has the real monitor's
# name swapped for the nested output's, so per-monitor settings like the scale still apply.
#
# Usage: Scripts/dev/test-env.sh <command> [args]
#   start [--fresh]        start it (--fresh copies the real settings and cache again)
#   stop                   stop the shell and the nested Hyprland
#   restart                restart only the shell, picking up code changes
#   shot [name]            screenshot; prints the PNG's path
#   click X Y [button]     move the pointer and click (left|right|middle|none)
#   ipc <target> <fn> [..] qs ipc call on the test shell
#   settle [panel]         wait until `state panels` reports open:<panel> (or closed)
#   log                    the test shell's log
#   hypr <args>            hyprctl on the nested Hyprland
#   status                 whether it is running

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DIR="${FROSTALIA_TEST_ENV_DIR:-${XDG_RUNTIME_DIR:-/tmp}/frostalia-test-env}"
STATE="$DIR/instance"
# Size of the nested screen; the window rule's size has to match it
SIZE="${FROSTALIA_TEST_ENV_SIZE:-1920x1080}"
WIDTH="${SIZE%x*}"
HEIGHT="${SIZE#*x}"

die() {
  echo "test-env: $*" >&2
  exit 1
}

load() {
  [ -f "$STATE" ] || die "not running (Scripts/dev/test-env.sh start)"
  # shellcheck source=/dev/null
  . "$STATE"
  kill -0 "$NESTED_PID" 2>/dev/null || die "the nested Hyprland is gone (Scripts/dev/test-env.sh start)"
}

nested() {
  env WAYLAND_DISPLAY="$NESTED_SOCKET" HYPRLAND_INSTANCE_SIGNATURE="$NESTED_INSTANCE" "$@"
}

instances() {
  hyprctl instances -j | python3 -c 'import json, sys
for i in json.load(sys.stdin):
    print(i["instance"], i["wl_socket"], i["pid"])'
}

copy_home() {
  rm -rf "$DIR/config" "$DIR/cache"
  mkdir -p "$DIR/config" "$DIR/cache"
  cp -a "$HOME/.config/frostalia/." "$DIR/config/" 2>/dev/null || true
  cp -a "$HOME/.cache/frostalia/." "$DIR/cache/" 2>/dev/null || true
}

start_shell() {
  local cmd
  cmd="env FROSTALIA_CONFIG_DIR=$DIR/config/ FROSTALIA_CACHE_DIR=$DIR/cache/ dbus-run-session -- qs -p $ROOT --no-duplicate"
  nested hyprctl dispatch "hl.dsp.exec_cmd(\"$cmd >$DIR/shell.out 2>&1\")" >/dev/null
  for _ in $(seq 100); do
    if nested qs -p "$ROOT" ipc call state panels >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.2
  done
  die "the shell did not come up; see Scripts/dev/test-env.sh log or $DIR/shell.out"
}

# Killed by process id, never by config path: the real shell runs this same checkout
stop_shell() {
  local pid
  for pid in $(nested qs -p "$ROOT" list 2>/dev/null | awk '/Process ID:/ {print $3}'); do
    if qs list --all 2>/dev/null | grep -A3 "Process ID: $pid\$" | grep -q "Display connection: wayland,$NESTED_SOCKET\$"; then
      qs kill --pid "$pid" >/dev/null 2>&1 || true
    fi
  done
}

cmd_start() {
  if [ -f "$STATE" ] && (. "$STATE" && kill -0 "$NESTED_PID" 2>/dev/null); then
    echo "already running"
    return 0
  fi
  [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] || die "run this from the Hyprland session"
  mkdir -p "$DIR/shots"
  if [ "${1:-}" = "--fresh" ] || [ ! -d "$DIR/config" ]; then
    copy_home
  fi

  cat >"$DIR/hyprland.lua" <<EOF
-- Written by Scripts/dev/test-env.sh
package.path = "$HOME/.config/hypr/?.lua;" .. package.path
pcall(require, "shared/looknfeel")
pcall(require, "shared/input")
-- Like the real screen; left alone, the nested output picks scale 2
hl.monitor({ output = "WAYLAND-1", mode = "${WIDTH}x${HEIGHT}", position = "0x0", scale = 1.0 })
hl.config({
  misc = { disable_hyprland_logo = true, disable_splash_rendering = true },
  animations = { enabled = false },
  ecosystem = { no_update_news = true, no_donation_nag = true },
})
EOF

  # The real screen being mirrored: its name for the settings copy, its wallpaper
  REAL_OUTPUT="$(hyprctl monitors -j | python3 -c 'import json, sys
monitors = json.load(sys.stdin)
print(next((m["name"] for m in monitors if m["focused"]), monitors[0]["name"] if monitors else ""))')"

  local before
  before="$(instances | awk '{print $1}')"
  # Started by the real Hyprland, so its window gets the background window rule
  hyprctl dispatch "hl.dsp.exec_cmd(\"Hyprland -c $DIR/hyprland.lua >$DIR/hyprland.out 2>&1\")" >/dev/null

  local line=""
  for _ in $(seq 100); do
    line="$(instances | grep -vF "$before" | head -n1 || true)"
    [ -n "$line" ] && break
    sleep 0.1
  done
  [ -n "$line" ] || die "the nested Hyprland did not start; see $DIR/hyprland.out"
  read -r NESTED_INSTANCE NESTED_SOCKET NESTED_PID <<<"$line"
  printf 'NESTED_INSTANCE=%s\nNESTED_SOCKET=%s\nNESTED_PID=%s\n' "$NESTED_INSTANCE" "$NESTED_SOCKET" "$NESTED_PID" >"$STATE"

  # Wait for its output, then the wallpaper daemon and the shell
  for _ in $(seq 50); do
    nested hyprctl monitors 2>/dev/null | grep -q "^Monitor" && break
    sleep 0.1
  done
  local output
  output="$(nested hyprctl monitors -j | python3 -c 'import json, sys; print(json.load(sys.stdin)[0]["name"])')"
  if [ -n "$REAL_OUTPUT" ] && [ "$REAL_OUTPUT" != "$output" ]; then
    find "$DIR/config" -name '*.toml' -exec sed -i "s/\"$REAL_OUTPUT\"/\"$output\"/g" {} +
  fi

  nested hyprctl dispatch "hl.dsp.exec_cmd(\"awww-daemon >$DIR/awww.out 2>&1\")" >/dev/null || true
  local wallpaper
  wallpaper="$(awww query 2>/dev/null | grep -F "$REAL_OUTPUT:" | sed -n 's/.*currently displaying: image: //p' | head -n1)"
  if [ -n "$wallpaper" ]; then
    for _ in $(seq 30); do
      nested awww img --transition-type none "$wallpaper" >/dev/null 2>&1 && break
      sleep 0.1
    done
  fi
  nested hyprctl dismissnotify >/dev/null 2>&1 || true
  start_shell
  echo "running: $NESTED_SOCKET (workspace 100), files in $DIR"
}

cmd_stop() {
  [ -f "$STATE" ] || {
    echo "not running"
    return 0
  }
  # shellcheck source=/dev/null
  . "$STATE"
  if kill -0 "$NESTED_PID" 2>/dev/null; then
    stop_shell
    kill "$NESTED_PID" 2>/dev/null || true
  fi
  rm -f "$STATE"
  echo "stopped"
}

cmd_settle() {
  local want="${1:-}" state=""
  for _ in $(seq 60); do
    state="$(nested qs -p "$ROOT" ipc call state panels 2>/dev/null || true)"
    if { [ -z "$want" ] && [ "$state" = "closed" ]; } || [ "$state" = "open:$want" ]; then
      return 0
    fi
    sleep 0.1
  done
  die "did not settle (last state: ${state:-none})"
}

command="${1:-status}"
shift || true
case "$command" in
start) cmd_start "$@" ;;
stop) cmd_stop ;;
restart)
  load
  stop_shell
  sleep 0.3
  start_shell
  echo "shell restarted"
  ;;
shot)
  load
  out="$DIR/shots/${1:-shot}-$(date +%H%M%S).png"
  # Unfocused windows render at misc:render_unfocused_fps; let a frame land
  sleep 0.15
  nested grim "$out"
  echo "$out"
  ;;
click)
  load
  [ $# -ge 2 ] || die "usage: click X Y [left|right|middle|none]"
  nested python3 "$ROOT/Scripts/dev/test_env_pointer.py" "$@" --width "$WIDTH" --height "$HEIGHT"
  ;;
ipc)
  load
  nested qs -p "$ROOT" ipc call "$@"
  ;;
settle)
  load
  cmd_settle "$@"
  ;;
log)
  load
  nested qs -p "$ROOT" log "$@"
  ;;
hypr)
  load
  nested hyprctl "$@"
  ;;
status)
  if [ -f "$STATE" ] && (. "$STATE" && kill -0 "$NESTED_PID" 2>/dev/null); then
    cat "$STATE"
  else
    echo "not running"
  fi
  ;;
*) die "unknown command: $command" ;;
esac
