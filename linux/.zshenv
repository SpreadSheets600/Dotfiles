# =============================================================================
#  ~/.zshenv  —  environment for every zsh invocation
#  Managed in ~/Dotfiles/linux/.zshenv  (see SYSTEM.md)
#  Keep this file silent and fast: scripts and non-interactive shells read it.
# =============================================================================

# --- XDG base directories -----------------------------------------------------
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# --- Locale -------------------------------------------------------------------
export LANG="${LANG:-en_US.UTF-8}"

# --- PATH (unique, user-first) ------------------------------------------------
typeset -U path PATH
path=(
  "$HOME/.local/bin"
  "$HOME/bin"
  "$HOME/.opencode/bin"
  "$HOME/.bun/bin"
  "$HOME/go/bin"
  "$HOME/.cargo/bin"
  $path
)
export PATH

# --- Editor / pager / man -----------------------------------------------------
if (( $+commands[nvim] )); then
  export EDITOR=nvim
  export VISUAL=nvim
else
  export EDITOR=nano
  export VISUAL=nano
fi

export PAGER=less
export LESS='-R --use-color -Dd+r$Du+b'
export MANPAGER="less -R"
(( $+commands[nvim] )) && export MANPAGER='nvim +Man!'
export MANWIDTH=100

# --- CLI tool defaults --------------------------------------------------------
export BAT_THEME="Catppuccin Mocha"
export ZSH_COMPDUMP="$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION"

# Let programs write runtime state to the right place.
export LESSHISTFILE="$XDG_STATE_HOME/lesshst"
