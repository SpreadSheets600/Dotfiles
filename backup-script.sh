#!/bin/bash

set -e

CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/Dotfiles"
HOME_BACKUP_DIR="$BACKUP_DIR/home"

DATE=$(date +%Y-%m-%d)

COMMIT_MSG="feat: dotfiles update $DATE"

CONFIG_ITEMS=(
    "autostart"
    "cava"
    "starship.toml"
    "fastfetch"
    "MangoHud"  
    "goverlay"
    "niri"
    "zsh"
    "shell"
)

HOME_ITEMS=(
    ".zshrc"
    ".zshenv"
    ".zprofile"
)

mkdir -p "$BACKUP_DIR"
mkdir -p "$HOME_BACKUP_DIR"
echo "Backing Up Dotfiles ..."

for item in "${CONFIG_ITEMS[@]}"; do
  SRC="$CONFIG_DIR/$item"
  DEST="$BACKUP_DIR/$item"
  
  if [ -e "$SRC" ]; then
    rm -rf "$DEST"
    cp -a "$SRC" "$DEST"
    echo " $item Backed Up In Dotfiles"
  else
    echo " $item Not Found In ~/.config ( Skipped )"
  fi
done

for item in "${HOME_ITEMS[@]}"; do
  SRC="$HOME/$item"
  DEST="$HOME_BACKUP_DIR/$item"

  if [ -e "$SRC" ]; then
    cp -a "$SRC" "$DEST"
    echo " $item Backed Up In Dotfiles/home"
  else
    echo " $item Not Found In ~ ( Skipped )"
  fi
done

echo "Committing Changes ..."

cd "$BACKUP_DIR"

git add .
git commit -m "$COMMIT_MSG"

echo "Pushing To Remote..."
git push

echo "Done! Dotfiles Updated And Pushed."
