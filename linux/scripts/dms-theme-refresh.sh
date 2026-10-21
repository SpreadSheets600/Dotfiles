#!/usr/bin/env bash
# dms-theme-refresh.sh — regenerate every DMS/matugen theme from the current
# wallpaper. DMS normally does this automatically; use this after installing a
# new themed app or when a template did not refresh.
set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/DankMaterialShell"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/DankMaterialShell"
SESSION_FILE="$STATE_DIR/session.json"

command -v dms >/dev/null 2>&1 || {
  printf 'dms-theme-refresh: dms not found\n' >&2
  exit 1
}

[[ -f $SESSION_FILE ]] || {
  printf 'dms-theme-refresh: missing %s\n' "$SESSION_FILE" >&2
  exit 1
}

wallpaper="$(jq -r '.wallpaperPath // empty' "$SESSION_FILE" 2>/dev/null || true)"
if [[ -z $wallpaper || ! -f $wallpaper ]]; then
  printf 'dms-theme-refresh: no current wallpaper found\n' >&2
  exit 1
fi

shell_dir="$(find "/run/user/$(id -u)/danklinux-shell" -maxdepth 2 -name shell.qml \
  -printf '%T@ %h\n' 2>/dev/null | sort -nr | head -n 1 | cut -d' ' -f2-)"
if [[ -z $shell_dir ]]; then
  printf 'dms-theme-refresh: DMS shell directory not found; is DMS running?\n' >&2
  exit 1
fi

mode="$(dms ipc call theme getMode 2>/dev/null | tr -d '[:space:]' || true)"
case $mode in
  light|dark|smart) ;;
  *) mode=dark ;;
esac

printf 'dms-theme-refresh: wallpaper = %s, mode = %s\n' "$wallpaper" "$mode"
exec dms matugen generate \
  --kind image \
  --value "$wallpaper" \
  --mode "$mode" \
  --state-dir "$STATE_DIR" \
  --config-dir "$CONFIG_DIR" \
  --shell-dir "$shell_dir"
