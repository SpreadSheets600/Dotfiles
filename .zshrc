export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="blokkzh"

plugins=(
  z
  fzf
  git
  autoenv
  gitfast
  git-extras
  zsh-completions
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-history-substring-search
)

source $ZSH/oh-my-zsh.sh

globalias() {
  if [[ $LBUFFER =~ '[a-zA-Z0-9]+$' ]]; then
    zle _expand_alias
    zle expand-word
  fi
  zle self-insert
}

zle -N globalias
bindkey " " globalias
bindkey "^ " magic-space
bindkey "^[[Z" magic-space
bindkey -M isearch " " magic-space
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

. ~/.zsh_aliases
