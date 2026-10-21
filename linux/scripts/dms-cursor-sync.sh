#!/usr/bin/env bash
# Keep every cursor consumer in sync with DMS.
#
# DMS owns cursorSettings.theme/size, writes niri/dms/cursor.kdl and updates
# .Xresources, but it does not update GTK, GSettings, ~/.icons/default, or
# reload niri. WCursor does all of those; run it without touching DMS so the
# shell is not restarted just to sync the remaining targets.
set -euo pipefail

PATH="$HOME/.local/bin:$PATH"
settings="${XDG_CONFIG_HOME:-$HOME/.config}/DankMaterialShell/settings.json"

[[ -r $settings ]] || exit 0
command -v jq >/dev/null 2>&1 || exit 0
command -v wcursor >/dev/null 2>&1 || exit 0

# Coalesce rapid changes: DMS rewrites cursor.kdl several times while the
# cursor picker is open. Only the newest invocation should apply the result.
runtime="${XDG_RUNTIME_DIR:-/tmp}/dms-cursor-sync"
mkdir -p "$runtime"
stamp="$runtime/stamp"
token="$(date +%s%N)"
printf '%s\n' "$token" > "$stamp"
sleep 1
[[ $(cat "$stamp" 2>/dev/null || true) == "$token" ]] || exit 0

theme=$(jq -r '.cursorSettings.theme // empty' "$settings" 2>/dev/null || true)
size=$(jq -r '.cursorSettings.size // empty' "$settings" 2>/dev/null || true)

# DMS and GTK handle System Default themselves; WCursor only manages themes
# installed under ~/.local/share/icons. System themes such as Adwaita are
# skipped instead of making the service fail.
[[ -n $theme && $theme != "System Default" ]] || exit 0
[[ -d "$HOME/.local/share/icons/$theme/cursors" ]] || exit 0
[[ -n $size ]] || size=24

wcursor set "$theme" --size "$size" --no-dms
