#!/usr/bin/env zsh
[[ $- != *i* ]] && return

# ---------------------------------------------------
# PATHS & CACHE
# ---------------------------------------------------
export ZSH_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
export ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
mkdir -p "$ZSH_CACHE_HOME" "$(dirname $ZINIT_HOME)"

# ---------------------------------------------------
# ZINIT INSTALL
# ---------------------------------------------------
if [[ ! -d $ZINIT_HOME/.git ]]; then
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "$ZINIT_HOME/zinit.zsh"

# ---------------------------------------------------
# PLUGINS 
# ---------------------------------------------------
# Autosuggestions
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#6c7086"
zinit light zsh-users/zsh-autosuggestions

# History Search
zinit ice wait lucid depth=1
zinit light zsh-users/zsh-history-substring-search
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Syntax Highlighting
zinit ice wait lucid depth=1
zinit light zdharma-continuum/fast-syntax-highlighting

# Completions
zinit ice wait lucid depth=1
zinit light zsh-users/zsh-completions
autoload -Uz compinit && compinit -d "$ZSH_CACHE_HOME/.zcompdump"

# Fuzzy Tab Completion
zinit ice wait lucid depth=1
zinit light Aloxaf/fzf-tab
zstyle ':fzf-tab:*' use-fzf-default-opts yes
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --tree --color=always $realpath | head -200'

# LS Colors Theme
vivid_theme="catppuccin-mocha"
zinit ice wait lucid depth=1
zinit light ryanccn/vivid-zsh
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Utilities
zinit ice wait"2"
zinit light ael-code/zsh-colored-man-pages

zinit snippet OMZP::sudo
zinit snippet OMZP::command-not-found

# ---------------------------------------------------
# OPTIONS
# ---------------------------------------------------
setopt AUTO_CD EXTENDED_GLOB NO_CASE_GLOB
setopt HIST_IGNORE_ALL_DUPS SHARE_HISTORY
setopt INC_APPEND_HISTORY HIST_REDUCE_BLANKS
setopt AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_MINUS
setopt INTERACTIVE_COMMENTS CORRECT
setopt GLOB_DOTS NUMERIC_GLOB_SORT NO_BEEP

# ---------------------------------------------------
# HISTORY
# ---------------------------------------------------
export HISTFILE="$ZSH_CACHE_HOME/history"
HISTSIZE=50000
SAVEHIST=50000

# ---------------------------------------------------
# KEYBINDS
# ---------------------------------------------------
bindkey -e
KEYTIMEOUT=10

bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5A' up-line-or-history
bindkey '^[[1;5B' down-line-or-history

bindkey '^[[3;5~' kill-word
bindkey '^H' backward-kill-word

# ---------------------------------------------------
# COMPLETION
# ---------------------------------------------------
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$ZSH_CACHE_HOME/completion"

# ---------------------------------------------------
# FZF
# ---------------------------------------------------
if command -v fzf &>/dev/null; then
  source <(fzf --zsh)
export FZF_DEFAULT_OPTS="
  --height 40%
  --layout=reverse
  --border=rounded
  --info=right"

  export FZF_CTRL_T_OPTS="
  --preview 'bat --color=always --line-range :200 {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"

  export FZF_ALT_C_OPTS="
  --preview 'eza --tree --color=always {} | head -200'"
fi

# ---------------------------------------------------
# NAVIGATION (Zoxide)
# ---------------------------------------------------
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
  alias j='zoxide query -l | fzf --preview "eza --tree --color=always {} | head -200" | xargs -r cd'
fi

# ---------------------------------------------------
# ALIASES
# ---------------------------------------------------
alias ls='eza --icons'
alias l='eza -l --icons'
alias la='eza -a --icons'
alias ll='eza -la --icons'
alias lt='eza --tree --icons'

alias cat='bat'
alias grep='rg'

alias g='git'
alias k='kubectl'

alias ff='fzf --preview "bat --color=always {}"'
alias fh='history | fzf'
alias fcd='cd $(fd -t d | fzf)'

alias extract='aunpack'

alias pg-start='systemctl start postgresql.service'
alias pg-stop='systemctl stop postgresql.service'
alias pg-status='systemctl status postgresql.service'

alias ref='exec zsh'

alias backup='./Dotfiles/backup-script.sh'

# ---------------------------------------------------
# PROMPT (Starship)
# ---------------------------------------------------
if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
fi

# ---------------------------------------------------
# EXTRA PATH
# ---------------------------------------------------
export PATH="$HOME/.opencode/bin:$PATH"

# ---------------------------------------------------
# Autorun
# ---------------------------------------------------
"${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch/run-fastfetch.sh"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Amp CLI
export PATH="$HOME/.local/bin:$PATH"
