#!/usr/bin/env zsh

# System Zsh config points ZDOTDIR here, so forward interactive shell startup
# to the user-owned config in $HOME.
[[ -f ~/.zshrc ]] && source ~/.zshrc
