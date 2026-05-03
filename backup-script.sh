#!/bin/bash

set -e

CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/Dotfiles"

DATE=$(date +%Y-%m-%d)

COMMIT_MSG="feat: dotfiles update $DATE"

ITEMS=(
    "autostart"
    "cava"
    "starship.toml"
    "fastfetch"
    "MangoHud"  
    "goverlay"
    "niri"
)


mkdir -p "$BACKUP_DIR"
echo "Backing Up Dotfiles ..."

for item in "${ITEMS[@]}"; do
  SRC="$CONFIG_DIR/$item"
  DEST="$BACKUP_DIR/$item"
  
  if [ -e "$SRC" ]; then
    cp -a "$SRC" "$DEST"
    echo " $item Backed Up In Dotfiles"
  else
    echo " $item Not Found In ~/.config ( Skipped )"
  fi
done

echo "Committing Changes ..."

cd $BACKUP_DIR

git add .
git commit -m "$COMMIT_MSG"

echo "Pushing To Remote..."
git push

echo "Done! Dotfiles Updated And Pushed."
