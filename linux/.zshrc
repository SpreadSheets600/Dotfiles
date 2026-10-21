# =============================================================================
#
#   .zshrc — interactive zsh configuration
#   Managed in ~/Dotfiles/linux/.zshrc — see SYSTEM.md
#
#   Prompt : Powerlevel10k (DMS "ii" purple palette)
#   Plugins: zsh-autosuggestions, zsh-syntax-highlighting,
#            zsh-history-substring-search, zsh-completions, fzf
#   Tools  : eza, bat, fd, ripgrep, fzf, zoxide, yazi, lazygit, vivid, direnv
#
# =============================================================================

# Powerlevel10k instant prompt must be configured before anything writes to the
# terminal. It makes new shells appear instantly even with a large config.
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
typeset -g POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true

# Nothing below is needed in non-interactive shells.
[[ $- == *i* ]] || return

# =============================================================================
#  History
# =============================================================================
export HISTFILE="$XDG_STATE_HOME/zsh/history"
export HISTSIZE=100000
export SAVEHIST=100000

setopt EXTENDED_HISTORY          # store timestamps + duration
setopt HIST_EXPIRE_DUPS_FIRST    # drop old duplicates first
setopt HIST_IGNORE_DUPS          # never store consecutive duplicates
setopt HIST_IGNORE_ALL_DUPS      # remove older duplicate entries
setopt HIST_IGNORE_SPACE         # ignore commands starting with a space
setopt HIST_FIND_NO_DUPS         # don't show duplicates while searching
setopt HIST_SAVE_NO_DUPS         # don't write duplicates to the file
setopt HIST_REDUCE_BLANKS        # trim extra whitespace
setopt HIST_VERIFY               # show expanded history before running
setopt SHARE_HISTORY             # sync across terminals immediately

# =============================================================================
#  Shell behaviour
# =============================================================================
setopt AUTO_CD                   # `dir` instead of `cd dir`
setopt AUTO_PUSHD                # `cd` builds a directory stack
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_TO_HOME
setopt EXTENDED_GLOB
setopt GLOB_DOTS
setopt NO_CASE_GLOB
setopt INTERACTIVE_COMMENTS
setopt NO_BEEP
setopt MULTIOS
setopt COMPLETE_IN_WORD
setopt ALWAYS_TO_END
setopt RC_QUOTES
setopt PROMPT_SUBST
setopt NO_FLOW_CONTROL          # allow Ctrl+S / Ctrl+Q
setopt APPEND_HISTORY

# =============================================================================
#  Completion
# =============================================================================
mkdir -p "$XDG_CACHE_HOME/zsh" "$XDG_STATE_HOME/zsh"

autoload -Uz compinit
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION"

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list \
  'm:{a-zA-Z}={A-Za-z}' \
  'r:|=*' \
  'l:|=* r:|=*'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/zcompcache"
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{245}── %d ──%f'
zstyle ':completion:*:messages' format '%F{183}%d%f'
zstyle ':completion:*:warnings' format '%F{203}no match: %d%f'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:sudo:*' command-path \
  /usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin

# =============================================================================
#  Colours (vivid + Catppuccin Mocha)
# =============================================================================
if (( $+commands[vivid] )); then
  export LS_COLORS="$(vivid generate catppuccin-mocha)"
fi

# =============================================================================
#  Plugins (Arch packages, no network at shell startup)
# =============================================================================
ZSH_PLUGINS=/usr/share/zsh/plugins

[[ -r $ZSH_PLUGINS/zsh-autosuggestions/zsh-autosuggestions.zsh ]] &&
  source $ZSH_PLUGINS/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#6c6c74'

[[ -r $ZSH_PLUGINS/zsh-history-substring-search/zsh-history-substring-search.zsh ]] &&
  source $ZSH_PLUGINS/zsh-history-substring-search/zsh-history-substring-search.zsh

# Optional: fzf-tab, if installed (paru -S zsh-fzf-tab)
if [[ -r $ZSH_PLUGINS/fzf-tab/fzf-tab.zsh ]]; then
  source $ZSH_PLUGINS/fzf-tab/fzf-tab.zsh
  zstyle ':fzf-tab:*' use-fzf-default-opts yes
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --tree --level=2 --color=always --icons=auto $realpath'
  zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'systemctl status $word 2>/dev/null'
fi

# fzf's native shell integration
if (( $+commands[fzf] )); then
  source <(fzf --zsh)
fi

# Syntax highlighting is always loaded last.
[[ -r $ZSH_PLUGINS/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] &&
  source $ZSH_PLUGINS/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# =============================================================================
#  Key bindings (emacs mode)
# =============================================================================
bindkey -e
KEYTIMEOUT=1

bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^P'   history-substring-search-up
bindkey '^N'   history-substring-search-down

bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word
bindkey '^[b'     backward-word
bindkey '^[f'     forward-word
bindkey '^[[H'    beginning-of-line
bindkey '^[[F'    end-of-line
bindkey '^[[3~'   delete-char
bindkey '^H'      backward-kill-word
bindkey '^[[3;5~' kill-word
bindkey '^[[Z'    reverse-menu-complete

WORDCHARS='*?_-.[]~=/&;!#$%^(){}<>'

# =============================================================================
#  fzf defaults
# =============================================================================
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --strip-cwd-prefix --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --strip-cwd-prefix --exclude .git'
export FZF_DEFAULT_OPTS="
  --height=60%
  --layout=reverse
  --border=rounded
  --info=inline-right
  --prompt='  '
  --pointer='▶'
  --marker='✓'
  --color=fg:#e6e0e9,fg+:#f4efff,bg+:#2b2930,hl:#d0bcff,hl+:#d0bcff
  --color=info:#cac4d0,prompt:#d0bcff,pointer:#d0bcff,marker:#7fff9a
  --color=spinner:#d0bcff,header:#cac4d0,border:#49454f"
export FZF_CTRL_T_OPTS="
  --preview 'bat --style=numbers,changes --color=always --line-range :200 {}'
  --preview-window=right:60%:wrap"
export FZF_ALT_C_OPTS="
  --preview 'eza --tree --level=2 --color=always --icons=auto {} | head -100'
  --preview-window=right:60%:wrap"

# =============================================================================
#  Navigation & integrations
# =============================================================================
if (( $+commands[zoxide] )); then
  eval "$(zoxide init zsh)"
fi

if (( $+commands[direnv] )); then
  eval "$(direnv hook zsh)"
fi

# GPG/SSH agent helpers for git commit signing.
export GPG_TTY=$(tty)

# =============================================================================
#  Aliases — files & search
# =============================================================================
alias ls='eza --icons=auto --group-directories-first'
alias l='eza -l --icons=auto --group-directories-first'
alias la='eza -la --icons=auto --group-directories-first'
alias ll='eza -lh --icons=auto --group-directories-first --git'
alias lt='eza --tree --level=2 --icons=auto'
alias lta='eza --tree --level=3 --icons=auto -a'
alias tree='eza --tree --icons=auto'

alias cat='bat --paging=never'
alias catp='bat'
alias grep='rg'
# (fd is available as `fd`; find is left untouched)
alias du='dust'
alias df='duf'
alias ps='procs'
alias top='btop'
alias ports='ss -tulpn'

# =============================================================================
#  Aliases — editors & tools
# =============================================================================
alias vim='nvim'
alias vi='nvim'
alias n='nvim'
alias lg='lazygit'
alias tldr='tealdeer'
alias fetch='fastfetch'

# =============================================================================
#  Aliases — git
# =============================================================================
alias g='git'
alias gs='git status -sb'
alias gd='git diff'
alias gds='git diff --staged'
alias ga='git add'
alias gaa='git add -A'
alias gc='git commit'
alias gcm='git commit -m'
alias gp='git push'
alias gpl='git pull --rebase'
alias gl='git log --oneline --graph --decorate -20'
alias gco='git checkout'
alias gsw='git switch'
alias gb='git branch'
alias gst='git stash'
alias gr='git restore'

# =============================================================================
#  Aliases — system
# =============================================================================
if (( $+commands[paru] )); then
  alias p='paru'
  alias up='paru -Syu'
  alias clean='paru -Sc'
else
  alias p='sudo pacman'
  alias up='sudo pacman -Syu'
fi
alias please='sudo'
alias reload='exec zsh -l'
alias sz='source ~/.zshrc'
alias myip='curl -s https://ifconfig.me && echo'

# =============================================================================
#  Functions
# =============================================================================
mkcd() {
  [[ -n $1 ]] || { print -u2 'usage: mkcd <directory>'; return 1 }
  mkdir -p -- "$1" && builtin cd -- "$1"
}
take() { mkcd "$@"; }

# yazi wrapper that returns to the last visited directory
y() {
  local tmp cwd
  tmp="$(mktemp -t yazi-cwd.XXXXXX)" || return 1
  yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd < "$tmp"
  [[ -n $cwd && $cwd != $PWD ]] && builtin cd -- "$cwd"
  rm -f -- "$tmp"
}

extract() {
  [[ -f $1 ]] || { print -u2 "extract: no such file: $1"; return 1 }
  case $1 in
    *.tar.bz2|*.tbz2) bsdtar -xf "$1" ;;
    *.tar.gz|*.tgz)   bsdtar -xf "$1" ;;
    *.tar.xz|*.txz)   bsdtar -xf "$1" ;;
    *.tar.zst|*.tzst) bsdtar -xf "$1" ;;
    *.tar)            bsdtar -xf "$1" ;;
    *.zip)            bsdtar -xf "$1" ;;
    *.7z)             7z x "$1" ;;
    *.rar)            bsdtar -xf "$1" ;;
    *.gz)             gunzip "$1" ;;
    *.bz2)            bunzip2 "$1" ;;
    *.xz)             unxz "$1" ;;
    *.zst)            unzstd "$1" ;;
    *) print -u2 "extract: unsupported archive: $1"; return 1 ;;
  esac
}

fh() {
  local cmd
  cmd=$(fc -ln -1000 | fzf --tac --no-sort --prompt='history ❯ ')
  [[ -n $cmd ]] && print -z -- "$cmd"
}

fcd() {
  local dir
  dir=$(fd --type d --hidden --exclude .git | fzf --prompt='cd ❯ ' \
    --preview 'eza --tree --level=2 --color=always --icons=auto {} | head -100')
  [[ -n $dir ]] && builtin cd -- "$dir"
}

# Quick package lookup: `pkg <file>` tells you which package owns/provides it.
pkg() {
  [[ -n $1 ]] || { print -u2 'usage: pkg <file-or-command>'; return 1 }
  local target
  target=$(command -v -- "$1" 2>/dev/null) || target=$1
  pkgfile --verbose -- "$target" 2>/dev/null ||
    paru -F -- "$target" 2>/dev/null ||
    print -u2 "pkg: nothing found for $1"
}

# Friendly command-not-found using pkgfile's database.
command_not_found_handler() {
  local pkgs
  pkgs=$(pkgfile --brief -- "$1" 2>/dev/null | head -n 5)
  print -u2 "zsh: command not found: $1"
  if [[ -n $pkgs ]]; then
    print -u2 "Provided by:"
    print -u2 "$pkgs"
  fi
  return 127
}

# =============================================================================
#  Prompt — Powerlevel10k
# =============================================================================
P10K_THEME=/usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme
if [[ -r $P10K_THEME ]]; then
  source $P10K_THEME
  [[ -r ~/.p10k.zsh ]] && source ~/.p10k.zsh
else
  PROMPT='%F{183}%~%f %# '
fi

# =============================================================================
#  Greeting (only for the first shell in a terminal, opt out with NOFETCH=1)
# =============================================================================
if [[ -z $NOFETCH && -z $TMUX && -z $ZELLIJ ]]; then
  () {
    emulate -L zsh
    local marker="${XDG_RUNTIME_DIR:-/tmp}/dotfiles-fetch-${KITTY_WINDOW_ID:-$$}"
    [[ -e $marker ]] && return
    : > "$marker" 2>/dev/null
    (( $+commands[fastfetch] )) &&
      fastfetch --config "$XDG_CONFIG_HOME/fastfetch/config.jsonc" 2>/dev/null
  }
fi
