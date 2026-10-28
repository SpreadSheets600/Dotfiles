#!/usr/bin/env bash

set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LINUX_DIR="$REPO_DIR/linux"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
BIN_HOME="$HOME/.local/bin"
BACKUP_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles-backups/$(date +%Y%m%d-%H%M%S)"

DRY_RUN=0

usage() {
  printf '%s\n' \
    'Usage:' \
    '  ./install.sh            back up conflicting files, then symlink' \
    '  ./install.sh --dry-run  show what would happen' \
    '' \
    'Existing files are moved to:' \
    '  ~/.local/state/dotfiles-backups/<timestamp>/'
}

ok() { printf '  \033[32m✓\033[0m %s\n' "$*"; }
moved() { printf '  \033[33m↳\033[0m %s\n' "$*"; }
dry() { printf '  \033[36m·\033[0m %s\n' "$*"; }

for arg in "$@"; do
  case $arg in
    -n|--dry-run) DRY_RUN=1 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'unknown option: %s\n' "$arg" >&2; exit 1 ;;
  esac
done

link_path() {
  local src=$1 dest=$2

  if [[ -L $dest && $(readlink -f -- "$dest") == $(readlink -m -- "$src") ]]; then
    ok "$dest (already linked)"
    return
  fi

  if [[ $DRY_RUN == 1 ]]; then
    if [[ -e $dest || -L $dest ]]; then
      dry "would back up $dest and link to $src"
    else
      dry "would link $dest -> $src"
    fi
    return
  fi

  if [[ -e $dest || -L $dest ]]; then
    local rel=${dest#"$HOME"/}
    mkdir -p -- "$BACKUP_DIR/$(dirname -- "$rel")"
    mv -- "$dest" "$BACKUP_DIR/$rel"
    moved "backed up $dest"
  fi

  mkdir -p -- "$(dirname -- "$dest")"
  ln -s -- "$src" "$dest"
  ok "$dest -> $src"
}

prune_links() {
  local dir=$1 link target

  [[ -d $dir ]] || return 0

  for link in "$dir"/*; do
    [[ -L $link ]] || continue
    target=$(readlink -f -- "$link" 2>/dev/null || true)
    [[ $target == "$REPO_DIR"/* ]] || continue
    [[ -e $target ]] && continue

    if [[ $DRY_RUN == 1 ]]; then
      dry "would remove stale link $link"
    else
      rm -f -- "$link"
      moved "removed stale link $link"
    fi
  done
}

printf '\n\033[1mDotfiles installer\033[0m\n'
printf 'repo:   %s\n' "$REPO_DIR"
printf 'backup: %s\n\n' "$BACKUP_DIR"

prune_links "$BIN_HOME"

for file in .zshenv .zprofile .zshrc .p10k.zsh .gitconfig; do
  [[ -e $LINUX_DIR/$file ]] && link_path "$LINUX_DIR/$file" "$HOME/$file"
done

if [[ -d $LINUX_DIR/.config ]]; then
  for src in "$LINUX_DIR"/.config/*; do
    [[ -e $src ]] || continue
    link_path "$src" "$CONFIG_HOME/$(basename -- "$src")"
  done
fi

if [[ -d $LINUX_DIR/scripts ]]; then
  for src in "$LINUX_DIR"/scripts/*.sh; do
    [[ -e $src ]] || continue
    chmod +x "$src"
    link_path "$src" "$BIN_HOME/$(basename -- "$src")"
  done
fi

if [[ ! -d $REPO_DIR/wallpapers/Wallpapers ]] && [[ $DRY_RUN == 0 ]]; then
  git -C "$REPO_DIR" submodule update --init --recursive 2>/dev/null || true
fi

link_path "$REPO_DIR/wallpapers/Wallpapers" "$HOME/Pictures/Wallpapers"

if [[ $DRY_RUN == 0 ]] && command -v gsettings >/dev/null 2>&1; then
  gsettings set org.gnome.desktop.interface font-name 'ZedMono Nerd Font 11' 2>/dev/null || true
  gsettings set org.gnome.desktop.interface monospace-font-name 'ZedMono Nerd Font 11' 2>/dev/null || true
  gsettings set org.gnome.desktop.interface icon-theme 'Numix-Square' 2>/dev/null || true
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
  fc-cache -f >/dev/null 2>&1 || true
  ok "desktop font: ZedMono Nerd Font / icons: Numix-Square"
fi

printf '\nDone. Open a new terminal (or run: exec zsh -l).\n'

if [[ $DRY_RUN == 0 ]]; then
  printf 'Previous files are safe in: %s\n\n' "$BACKUP_DIR"
fi
