# =============================================================================
#  ~/.p10k.zsh — Powerlevel10k configuration
#  Managed in ~/Dotfiles/linux/.p10k.zsh
#
#  Palette matches the DMS "ii" theme used by kitty:
#    background #141218 · text #e6e0e9 · accent #d0bcff
#    green #7fff9a · yellow #ffda72 · red #ff728f · muted #cac4d0
# =============================================================================

# Temporarily disable aliases so that we can use the builtins defined below.
'builtin' 'local' '-a' 'p10k_config_opts'
[[ ! -o 'aliases'         ]] || p10k_config_opts+=('aliases')
[[ ! -o 'sh_glob'         ]] || p10k_config_opts+=('sh_glob')
[[ ! -o 'no_brace_expand' ]] || p10k_config_opts+=('no_brace_expand')
'builtin' 'setopt' 'no_aliases' 'no_sh_glob' 'brace_expand'

() {
  emulate -L zsh -o extended_glob

  # ---------------------------------------------------------------------------
  # Prompt layout
  # ---------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_MODE=nerdfont-complete
  typeset -g POWERLEVEL9K_ICON_PADDING=moderate

  typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
  typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=''
  typeset -g POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX=''
  typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_CHAR='·'
  typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_FOREGROUND=238
  typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_SUFFIX=''

  typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
    context
    dir
    vcs
    newline
    prompt_char
  )
  typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
    status
    command_execution_time
    background_jobs
    node_version
    python_version
    virtualenv
    kubecontext
    time
  )

  typeset -g POWERLEVEL9K_BACKGROUND=
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_{LEFT,RIGHT}_WHITESPACE=
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SUBSEGMENT_SEPARATOR=' '
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SEGMENT_SEPARATOR=
  typeset -g POWERLEVEL9K_VISUAL_IDENTIFIER_EXPANSION=''

  # ---------------------------------------------------------------------------
  # Prompt character
  # ---------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=183
  typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=203
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIINS_CONTENT_EXPANSION='❯'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VICMD_CONTENT_EXPANSION='❮'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIVIS_CONTENT_EXPANSION='❮'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIOWR_CONTENT_EXPANSION='❯'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL=''
  typeset -g POWERLEVEL9K_PROMPT_CHAR_LEFT_PROMPT_FIRST_SEGMENT_START_SYMBOL=''

  # ---------------------------------------------------------------------------
  # Context (user@host — only when it matters)
  # ---------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_CONTEXT_ROOT_FOREGROUND=203
  typeset -g POWERLEVEL9K_CONTEXT_{REMOTE,REMOTE_SUDO}_FOREGROUND=183
  typeset -g POWERLEVEL9K_CONTEXT_FOREGROUND=245
  typeset -g POWERLEVEL9K_CONTEXT_ROOT_TEMPLATE='%B%n@%m%f'
  typeset -g POWERLEVEL9K_CONTEXT_{REMOTE,REMOTE_SUDO}_TEMPLATE='%n@%m'
  typeset -g POWERLEVEL9K_CONTEXT_TEMPLATE='%n@%m'
  typeset -g POWERLEVEL9K_ALWAYS_SHOW_CONTEXT=false
  typeset -g POWERLEVEL9K_CONTEXT_SHOW_ON_COMMAND=''

  # ---------------------------------------------------------------------------
  # Directory
  # ---------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_DIR_FOREGROUND=183
  typeset -g POWERLEVEL9K_DIR_ANCHOR_FOREGROUND=183
  typeset -g POWERLEVEL9K_DIR_SHORTEN_STRATEGY=truncate_to_unique
  typeset -g POWERLEVEL9K_DIR_SHORTEN_DIR_LENGTH=1
  typeset -g POWERLEVEL9K_DIR_MAX_LENGTH=40
  typeset -g POWERLEVEL9K_DIR_HYPERLINK=false
  typeset -g POWERLEVEL9K_SHOW_RULER=false

  typeset -g POWERLEVEL9K_DIR_DEFAULT_VISUAL_IDENTIFIER_EXPANSION='󰉋'
  typeset -g POWERLEVEL9K_DIR_HOME_VISUAL_IDENTIFIER_EXPANSION='󰋜'
  typeset -g POWERLEVEL9K_DIR_HOME_SUBFOLDER_VISUAL_IDENTIFIER_EXPANSION='󰉋'
  typeset -g POWERLEVEL9K_DIR_ETC_VISUAL_IDENTIFIER_EXPANSION='󰒓'
  typeset -g POWERLEVEL9K_DIR_NOT_WRITABLE_VISUAL_IDENTIFIER_EXPANSION='󰌾'

  # ---------------------------------------------------------------------------
  # Git
  # ---------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_VCS_BRANCH_ICON='\uF126 '
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_ICON='?'
  typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND=114
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND=183
  typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=221
  typeset -g POWERLEVEL9K_VCS_CONFLICTED_FOREGROUND=203
  typeset -g POWERLEVEL9K_VCS_LOADING_FOREGROUND=245
  typeset -g POWERLEVEL9K_VCS_INCOMING_CHANGES_ICON='⇣'
  typeset -g POWERLEVEL9K_VCS_OUTGOING_CHANGES_ICON='⇡'
  typeset -g POWERLEVEL9K_VCS_STASH_ICON='*'
  typeset -g POWERLEVEL9K_VCS_TAG_ICON=''
  typeset -g POWERLEVEL9K_VCS_GIT_HOOKS=(
    vcs-detect-changes
    git-untracked
    git-aheadbehind
    git-stash
    git-remotebranch
    git-tags
  )
  typeset -g POWERLEVEL9K_VCS_SHOW_SUBMODULE_SYNC=true

  # ---------------------------------------------------------------------------
  # Status
  # ---------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_STATUS_VERBOSE=true
  typeset -g POWERLEVEL9K_STATUS_OK=false
  typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND=203
  typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL_FOREGROUND=203
  typeset -g POWERLEVEL9K_STATUS_ERROR_VISUAL_IDENTIFIER_EXPANSION='✘'
  typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL_VISUAL_IDENTIFIER_EXPANSION='✘'
  typeset -g POWERLEVEL9K_STATUS_OK_VISUAL_IDENTIFIER_EXPANSION='✔'

  # ---------------------------------------------------------------------------
  # Command timing & jobs
  # ---------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=2
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PRECISION=1
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=245
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FORMAT='d h m s'
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_VISUAL_IDENTIFIER_EXPANSION=''

  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND=245
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_VERBOSE=false

  # ---------------------------------------------------------------------------
  # Languages / environments
  # ---------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_NODE_VERSION_FOREGROUND=114
  typeset -g POWERLEVEL9K_NODE_VERSION_PROJECT_ONLY=true
  typeset -g POWERLEVEL9K_NODE_VERSION_VISUAL_IDENTIFIER_EXPANSION='󰎙'

  typeset -g POWERLEVEL9K_PYTHON_VERSION_FOREGROUND=221
  typeset -g POWERLEVEL9K_PYTHON_VERSION_PROJECT_ONLY=true
  typeset -g POWERLEVEL9K_PYTHON_VERSION_VISUAL_IDENTIFIER_EXPANSION='󰌠'

  typeset -g POWERLEVEL9K_VIRTUALENV_FOREGROUND=245
  typeset -g POWERLEVEL9K_VIRTUALENV_SHOW_PYTHON_VERSION=false
  typeset -g POWERLEVEL9K_VIRTUALENV_VISUAL_IDENTIFIER_EXPANSION='󰏗'

  typeset -g POWERLEVEL9K_KUBECONTEXT_FOREGROUND=183
  typeset -g POWERLEVEL9K_KUBECONTEXT_SHOW_ON_COMMAND='kubectl|helm|kubens|kubectx|oc|istioctl|k9s|flux|stern|kubeseal|kubecolor'
  typeset -g POWERLEVEL9K_KUBECONTEXT_VISUAL_IDENTIFIER_EXPANSION='󱃾'

  # ---------------------------------------------------------------------------
  # Time
  # ---------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_TIME_FOREGROUND=245
  typeset -g POWERLEVEL9K_TIME_FORMAT='%D{%H:%M}'
  typeset -g POWERLEVEL9K_TIME_UPDATE_ON_COMMAND=false
  typeset -g POWERLEVEL9K_TIME_VISUAL_IDENTIFIER_EXPANSION=''

  # ---------------------------------------------------------------------------
  # Instant prompt / transient prompt
  # ---------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
  typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=off
}

# Restore the options temporarily disabled above.
(( ${#p10k_config_opts} )) && setopt ${p10k_config_opts[@]}
'builtin' 'unset' 'p10k_config_opts'

# Tell Powerlevel10k that the config has been applied.
(( ! ${+functions[p10k]} )) || p10k finalize
