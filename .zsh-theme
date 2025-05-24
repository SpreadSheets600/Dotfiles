setopt prompt_subst

typeset -g LAST_CMD_START=0
typeset -g LAST_CMD_RUNTIME=0

preexec() {
    LAST_CMD_START=$SECONDS
}

precmd() {
    if [[ $LAST_CMD_START -ne 0 ]]; then
        LAST_CMD_RUNTIME=$(( SECONDS - LAST_CMD_START ))
    else
        LAST_CMD_RUNTIME=0
    fi
    LAST_CMD_START=0
}

function format_time() {
    local T=$1
    local H=$((T/3600))
    local M=$(((T/60)%60))
    local S=$((T%60))
    printf "%02d:%02d:%02d" $H $M $S
}

() {
    local PR_USER PR_PROMPT PR_HOST PR_AT
    local returnSymbol promptSymbolFrom promptSymbolTo promptSymbol rvmSymbol

    if [[ ${TERM} == "linux" ]]; then
        returnSymbol='<<'
        promptSymbolFrom='/-'
        promptSymbolTo='\-'
        promptSymbol='>'
        rvmSymbol='%F{red}rvm%f'
        ZSH_THEME_GIT_PROMPT_PREFIX='─[ %F{yellow} '
        ZSH_THEME_GIT_PROMPT_SUFFIX=' %f]'
        ZSH_THEME_VIRTUALENV_PREFIX='─[ %F{green}🐍 '
        ZSH_THEME_VIRTUALENV_SUFFIX=' %f]'
    else
        returnSymbol='↵'
        promptSymbolFrom='┌─'
        promptSymbolTo='└─'
        promptSymbol='➤'
        rvmSymbol='%F{red}🔻%f'
        ZSH_THEME_GIT_PROMPT_PREFIX='─[ %F{yellow} '
        ZSH_THEME_GIT_PROMPT_SUFFIX=' %f]'
        ZSH_THEME_VIRTUALENV_PREFIX='─[ %F{green}🐍 '
        ZSH_THEME_VIRTUALENV_SUFFIX=' %f]'
    fi

    if [[ $UID -eq 0 ]]; then
        PR_USER="%F{red}⚙ root%f"
    else
        PR_USER="%F{yellow} %n%f"
    fi

    if [[ -n "$SSH_CLIENT" || -n "$SSH2_CLIENT" ]]; then
        host_icon="%F{magenta}%f"
    else
        host_icon="%F{cyan}%f"
    fi

    PR_HOST="%F{white}%M%f"

    local user_host=" ${host_icon} ${PR_USER} "
    local current_dir=" %B%F{blue}%~%f%b "

    local rvm_ruby=''

    if ${HOME}/.rvm/bin/rvm-prompt &> /dev/null; then
        rvm_ruby="─[ ${rvmSymbol} %F{red}\$(${HOME}/.rvm/bin/rvm-prompt i v g s)%f ]"
    elif which rvm-prompt &> /dev/null; then
        rvm_ruby="─[ ${rvmSymbol} %F{red}\$(rvm-prompt i v g s)%f ]"
    elif which rbenv &> /dev/null; then
        rvm_ruby="─[ ${rvmSymbol} %F{red}\$(rbenv version | sed -e 's/ (set.*\$//')%f ]"
    fi

    local git_branch='$(git_prompt_info)'
    local venv_python='$(virtualenv_prompt_info)'
    local return_code="%(?..%F{red}%? ${returnSymbol}%f)"

    local first_line_left="${promptSymbolFrom}[${user_host}]─[${current_dir}]${rvm_ruby}${venv_python}${git_branch}"
    local second_line="${promptSymbolTo}${promptSymbol} "

    PROMPT="${first_line_left}
${second_line}"
}
