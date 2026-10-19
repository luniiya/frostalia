#!/usr/bin/env bash
# Install this Frostalia checkout as the user's frostalia config.
#
# Usage: ./install.sh [--copy] [--no-restart]
#   default       symlink ~/.config/quickshell/frostalia -> this repo (edits go live on restart)
#   --copy        copy the files instead of symlinking
#   --no-restart  don't restart the running shell afterwards
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/frostalia"
MODE="link"
RESTART=1

for arg in "$@"; do
  case "$arg" in
  --copy) MODE="copy" ;;
  --no-restart) RESTART=0 ;;
  -h | --help)
    sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'
    exit 0
    ;;
  *)
    echo "Unknown option: $arg" >&2
    exit 1
    ;;
  esac
done

if ! command -v qs >/dev/null 2>&1; then
  echo "Quickshell ('qs') not found. Install noctalia-qs first (e.g. 'paru -S noctalia-qs')." >&2
  exit 1
fi

if [ -e /etc/xdg/quickshell/frostalia ]; then
  echo "Note: a system copy exists at /etc/xdg/quickshell/frostalia."
  echo "      $TARGET takes precedence, but you can remove the package with: sudo pacman -Rns frostalia"
fi

# Build before changing the installation, so a failed build leaves it intact.
for helper in settings theming kdeconnect; do
  HELPER_DIR="$REPO_DIR/Tools/$helper"
  HELPER_BIN="$HELPER_DIR/target/release/frostalia-$helper"
  NEEDS_BUILD=0
  if [ ! -x "$HELPER_BIN" ]; then
    NEEDS_BUILD=1
  elif find "$HELPER_DIR/src" "$HELPER_DIR/Cargo.toml" "$HELPER_DIR/Cargo.lock" -type f -newer "$HELPER_BIN" -print -quit | grep -q .; then
    NEEDS_BUILD=1
  fi
  if [ "$NEEDS_BUILD" -eq 1 ]; then
    if ! command -v cargo >/dev/null 2>&1; then
      echo "Rust and Cargo are required to build Frostalia's helpers. Install your distribution's rust/cargo packages or use 'nix develop'." >&2
      exit 1
    fi
    echo "Building Frostalia's $helper helper..."
    CARGO_TARGET_DIR="$HELPER_DIR/target" cargo build --release --locked --manifest-path "$HELPER_DIR/Cargo.toml"
  fi
done

mkdir -p "$(dirname "$TARGET")"

# Back up whatever is there, unless it's already our symlink
if [ -L "$TARGET" ] && [ "$(readlink -f "$TARGET")" = "$REPO_DIR" ] && [ "$MODE" = "link" ]; then
  echo "Already linked: $TARGET -> $REPO_DIR"
elif [ -e "$TARGET" ] || [ -L "$TARGET" ]; then
  BACKUP="$TARGET.bak-$(date +%Y%m%d-%H%M%S)"
  echo "Backing up existing $TARGET -> $BACKUP"
  mv "$TARGET" "$BACKUP"
fi

if [ ! -e "$TARGET" ]; then
  if [ "$MODE" = "link" ]; then
    ln -s "$REPO_DIR" "$TARGET"
    echo "Linked $TARGET -> $REPO_DIR"
  else
    mkdir -p "$TARGET"
    tar -C "$REPO_DIR" --exclude=.git --exclude=./Tools/settings/target --exclude=./Tools/theming/target --exclude=./Tools/kdeconnect/target -cf - . | tar -C "$TARGET" -xf -
    for helper in settings theming kdeconnect; do
      mkdir -p "$TARGET/Tools/$helper/target/release"
      install -m 755 "$REPO_DIR/Tools/$helper/target/release/frostalia-$helper" "$TARGET/Tools/$helper/target/release/frostalia-$helper"
    done
    echo "Copied $REPO_DIR -> $TARGET"
  fi
fi

if [ "$RESTART" -eq 1 ] && [ -n "${WAYLAND_DISPLAY:-}" ]; then
  echo "Restarting frostalia..."
  qs -c frostalia kill >/dev/null 2>&1 || true
  sleep 0.5
  setsid -f qs -c frostalia >/dev/null 2>&1
fi

echo "Done. Launch manually with: qs -c frostalia"
