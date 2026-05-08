#!/usr/bin/env zsh

# System Zsh config points ZDOTDIR here, so forward interactive shell startup
# to the user-owned config in $HOME.
[[ -f ~/.zshrc ]] && source ~/.zshrc

# bun completions
[ -s "/home/spreadsheets600/.bun/_bun" ] && source "/home/spreadsheets600/.bun/_bun"

export PATH=$PATH:/home/spreadsheets600/.spicetify
