export SHELL=/usr/bin/zsh
export ZDOTDIR="$HOME"
export BUN_INSTALL="$HOME/.bun"

# Ensure UTF-8 locale to avoid strange glyphs
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export TERM=xterm-256color

typeset -U path PATH
path=(
  "$HOME/.local/bin"
  "$HOME/bin"
  "$BUN_INSTALL/bin"
  $path
)
export PATH
