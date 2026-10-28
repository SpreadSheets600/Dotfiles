#!/usr/bin/env bash

set -euo pipefail

DOTFILES="${DOTFILES_DIR:-$HOME/Dotfiles}"

printf 'Exporting configs to %s\n' "$DOTFILES"

mkdir -p \
  "$DOTFILES/linux/.config/fastfetch" \
  "$DOTFILES/shared/vscode"

cp -f ~/.zshrc "$DOTFILES/linux/.zshrc" 2>/dev/null || true
cp -f ~/.zprofile "$DOTFILES/linux/.zprofile" 2>/dev/null || true
cp -f ~/.p10k.zsh "$DOTFILES/linux/.p10k.zsh" 2>/dev/null || true
cp -f ~/.gitconfig "$DOTFILES/linux/.gitconfig" 2>/dev/null || true
cp -rf ~/.config/fastfetch/. "$DOTFILES/linux/.config/fastfetch/" 2>/dev/null || true
cp -f ~/.config/Code/User/settings.json "$DOTFILES/shared/vscode/settings.json" 2>/dev/null || true

find "$DOTFILES" -name "*.log" -delete 2>/dev/null || true
find "$DOTFILES" -name ".DS_Store" -delete 2>/dev/null || true

printf 'Done\n'
