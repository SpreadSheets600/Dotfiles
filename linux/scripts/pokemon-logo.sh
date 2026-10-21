#!/usr/bin/env bash
# =============================================================================
#  pokemon-logo.sh — random Pokémon sprite for the fastfetch greeting
#  Managed in ~/Dotfiles/linux/scripts/pokemon-logo.sh
#
#  pokeget draws its transparent/outline pixels as pure black. We remap those
#  to the DMS terminal background so the sprite blends into the terminal
#  instead of showing a black rectangle.
# =============================================================================

set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"

if ! command -v pokeget >/dev/null 2>&1; then
  exit 0
fi

# DMS "ii" background (#141218). Override with POKEMON_LOGO_BG if you change it.
bg="${POKEMON_LOGO_BG:-20;18;24}"

pokeget random --hide-name |
  sed -e "s/48;2;0;0;0m/48;2;${bg}m/g" \
      -e "s/38;2;0;0;0m/38;2;${bg}m/g"
