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

theme=$(jq -r '.cursorSettings.theme // empty' "$settings" 2>/dev/null || true)
size=$(jq -r '.cursorSettings.size // empty' "$settings" 2>/dev/null || true)

# DMS and GTK handle System Default themselves; WCursor only manages installed
# themes under ~/.local/share/icons.
[[ -n $theme && $theme != "System Default" ]] || exit 0
[[ -n $size ]] || size=24

# Let DMS finish writing settings.json and cursor.kdl before reading them.
sleep 0.5

exec wcursor set "$theme" --size "$size" --no-dms
