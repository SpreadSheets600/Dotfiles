#!/usr/bin/env bash
set -e

DOTFILES="$HOME/dotfiles"

echo "Updating dotfiles..."

mkdir -p "$DOTFILES/zsh"
mkdir -p "$DOTFILES/bash"
mkdir -p "$DOTFILES/fastfetch"
mkdir -p "$DOTFILES/vscode"
mkdir -p "$DOTFILES/scripts"

echo "Syncing Zsh..."
cp -f ~/.zshrc "$DOTFILES/zsh/.zshrc" 2>/dev/null || true
cp -f ~/.zprofile "$DOTFILES/zsh/.zprofile" 2>/dev/null || true
cp -rf ~/.zsh "$DOTFILES/zsh/" 2>/dev/null || true

echo "Syncing Bash..."
cp -f ~/.bashrc "$DOTFILES/bash/.bashrc" 2>/dev/null || true
cp -f ~/.bash_aliases "$DOTFILES/bash/.bash_aliases" 2>/dev/null || true

echo "Syncing Fastfetch..."
cp -rf ~/.config/fastfetch/* "$DOTFILES/fastfetch/" 2>/dev/null || true

echo "Syncing VSCode..."
cp -rf ~/.config/Code/User/* "$DOTFILES/vscode/" 2>/dev/null || true

echo "Syncing Scripts..."
cp -rf ~/scripts/* "$DOTFILES/scripts/" 2>/dev/null || true

echo "Cleaning junk..."
find "$DOTFILES" -name "*.log" -delete
find "$DOTFILES" -name ".DS_Store" -delete

echo "Done."
