#!/usr/bin/env bash

set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"

if ! command -v pokeget >/dev/null 2>&1; then
  exit 0
fi

BG="${POKEMON_LOGO_BG:-20;18;24}"

pokeget random --hide-name |
  sed -e "s/48;2;0;0;0m/48;2;${BG}m/g" \
      -e "s/38;2;0;0;0m/38;2;${BG}m/g"
