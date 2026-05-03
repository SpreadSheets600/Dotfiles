#!/usr/bin/env bash

set -euo pipefail

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/fastfetch"
CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch/config.jsonc"
LOGO_FILE="$CACHE_DIR/pokemon-logo.ansi"

mkdir -p "$CACHE_DIR"

if command -v pokeget >/dev/null 2>&1; then
  pokeget random --hide-name > "$LOGO_FILE"
fi

exec fastfetch --config "$CONFIG_FILE"
