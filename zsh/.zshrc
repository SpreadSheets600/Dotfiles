# ---------- PATH ----------
export PATH="/usr/local/bin:$HOME/.local/bin:$PATH"

source /usr/share/doc/fzf/examples/key-bindings.zsh
source /usr/share/doc/fzf/examples/completion.zsh

# ---------- HISTORY ----------
HISTFILE=$HOME/.zsh_history
HISTSIZE=20000
SAVEHIST=20000

setopt APPEND_HISTORY SHARE_HISTORY
setopt HIST_IGNORE_DUPS HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS EXTENDED_HISTORY

# ---------- COMPLETION ----------
autoload -Uz compinit
compinit -C -d ~/.zcompdump

# ---------- ZINIT ----------
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
source "$ZINIT_HOME/zinit.zsh"

# ---------- PLUGINS ----------

# Autosuggestions (async)
zinit light zsh-users/zsh-autosuggestions

# Syntax highlighting (must be near end)
zinit light zsh-users/zsh-syntax-highlighting

# History search
zinit light zsh-users/zsh-history-substring-search

# Smart cd
zinit light agkozak/zsh-z

# Extra completions
zinit light zsh-users/zsh-completions

# FZF (lazy)
zinit ice wait lucid
zinit light junegunn/fzf

# Git superpowers
zinit light zdharma-continuum/fast-syntax-highlighting
zinit light wfxr/forgit

# Docker/K8s helpers
zinit light greymd/docker-zsh-completion
zinit light jonmosco/kube-ps1

# ---------- PROMPT ----------
if command -v starship >/dev/null; then
  eval "$(starship init zsh)"
fi

# ---------- ALIASES ----------
alias ls='eza --icons'
alias l='eza -l --icons'
alias la='eza -a --icons'
alias ll='eza -la --icons'
alias lt='eza --tree --icons'

alias cat='batcat'
alias grep='rg'

alias g='git'
alias k='kubectl'

alias ff='fzf --preview "bat --style=numbers --color=always {}"'
alias fh='history | fzf'
alias fd='cd $(find . -type d | fzf)'

alias find='fd'

alias pg-start='sudo service postgresql start'
alias pg-status='sudo service postgresql status'
alias pg-stop='sudo service postgresql stop'

# ---------- PATH ------------------
# Zoxide
eval "$(zoxide init zsh)"

# Opencode
export PATH=/home/debian/.opencode/bin:$PATH

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# PNPM
export PNPM_HOME="/home/debian/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  


# ---------- ZSH KEYBINDINGS --------
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5A' up-line-or-history
bindkey '^[[1;5B' down-line-or-history

bindkey '^[[3;5~' kill-word
bindkey '^H' backward-kill-word

