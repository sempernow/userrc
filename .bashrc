# source .bashrc || source /etc/profile.d/${USER}-01-bashrc.sh

# Aliases

# Meta
alias os='cat /etc/os-release'
alias cpu='cat /proc/cpuinfo'
alias mem='cat /proc/meminfo'

# Apps
alias python=python3
alias pip='python3 -m pip'
[[ $(type -t vim) ]]    && alias vi=vim
[[ $(type -t go) ]]     && alias goclean='go clean -i -r -cache -testcache -fuzzcache'
[[ $(type -t ffmpeg) ]] && alias ffmpeg='ffmpeg -hide_banner'
[[ $(type -t gpg) ]]    && alias gpg=GnuPG
[[ $(type -t jq) ]]     && alias jq='jq -C'

# Scripts
[[ $(type -t openedit) ]] && alias edit=openedit
[[ $(type -t openedit) ]] && alias open=openedit
alias isdos=isDOS

# FS
alias ls='ls -hl --color=auto --group-directories-first'
alias -p |grep ' ll=' >/dev/null 2>&1 && unalias ll
alias ll='ls -AhlrtL --time-style=long-iso'
ll >/dev/null 2>&1 || alias ll='ls -AhlrtL --group-directories-first'
alias df='df -hT'
alias du='du -h'
alias lsblk='lsblk -o SIZE,LABEL,NAME,GROUP,MAJ:MIN,TYPE,FSTYPE,MIN-IO,MOUNTPOINT,UUID'
[[ $(type -t tree) ]] && alias tree='tree -I vendor --dirsfirst'
alias cp='cp -p'
alias copy='cp -up'
alias update='cp -urpv'

# Text
alias cls=clear
alias grep='grep --color'                       # show differences in colour
alias grepb='grep -B5'
alias grepa='grep -A5'
alias grepba='grep -B5 -A5'
# alias egrep='egrep --color=auto'              # show differences in colour
# alias fgrep='fgrep --color=auto'              # show differences in colour
alias sha2=sha256

# End here if not bash
[[ true ]] || { source ~/.bash_functions; return; }

# Network
ip -c addr > /dev/null 2>&1 && alias ip='ip -c'

# End here if previously sourced unless from /etc/profile.d/
[[ "$BASH_SOURCE" =~ "/etc/profile.d" ]] || {
    [[ "$isBashrcSourced" ]] && return
}
set -a # Export all
trap 'set +a' RETURN
#isBashrcSourced=1

# Test for GNU Bourne-Again SHell (bash)
[[ -n "${BASH_VERSION}" ]] && isBash=1    || unset isBash
[[ "$PATH" =~ 'Windows' ]] && isWindows=1 || unset isWindows
[[ "$(type -t wsl.exe)" ]] && hasWSL=1    || unset hasWSL

# If at bash and syntax not POSIX, then abide other (e.g., Process Substitution)
[[ "$isBash" ]] && set +o posix

# Source global definitions
[[ -f /etc/bashrc ]] && source /etc/bashrc

# Set sudo visudo editor
[[ $(type -t vi) ]] && VISUAL=$(which vi) && EDITOR=$(which vi)

# Preserve USER environment @ sudo su
[[ $HOME == /root ]] && home="$(pwd)" || home="$HOME"
# User specific environment
[[ -d $home/.local/bin ]] && {
    [[ "$PATH" =~ "$home/.local/bin:$home/bin:" ]] ||
        PATH="$home/.local/bin:$home/bin:$PATH"
}

# Configure to newest Golang version if any installed @ /usr/local/go[N.N.N]
[[ -d /usr/local ]] && GOROOT=$(find /usr/local -maxdepth 1 -type d -path '*/go*' |sort |tail -n 1)
[[ -d $GOROOT ]] && PATH=$GOROOT/bin:$PATH

# History (history) Options
#
# Ignore duplicates and statements starting with space(s)
HISTCONTROL=ignoreboth
# Ignore some controlling instructions
# HISTIGNORE is a colon-delimited list of patterns which should be excluded.
# The '&' is a special pattern which suppresses duplicate entries.
#HISTIGNORE=$'[ \t]*:&:[fb]g:exit'
[[ "$isBash" ]] && {
    shopt -s histappend
    shopt -s checkwinsize
}

# Umask
#
# /etc/profile sets 022, removing write perms to group + others.
# Set a more restrictive umask: i.e. no exec perms for others:
# umask 027
# Paranoid: neither group nor others have any perms:
# umask 077

# Source sibling configs unless already configured or configuring at all-users directory
set +a
[[ "$BASH_SOURCE" =~ "/etc/profile.d" ]] || {
    [[ -f "${home}/.bash_aliases" ]]   && source "${home}/.bash_aliases"
    [[ -f "${home}/.bash_functions" ]] && source "${home}/.bash_functions"
    for file in $(find $home -maxdepth 1 -type f -iname '.bashrc_*');do
        [[ -f "$file" ]] && source "$file"
    done
}

[[ -d $HOME/.nvm ]] && {
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"  # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
}

# End here if not interactive
#[[ "$-" != *i* ]] && return 0
[[ -z "$PS1" ]] && { unset home;return 0; }

# Programmable completion features
# may already be enabled at /etc/bash.bashrc,
# which is sourced by /etc/profile.
[[ $(type -t shopt) ]] && [[ ! "$(shopt -oq posix)" ]] &&
    [[ -f /usr/share/bash-completion/bash_completion ]] &&
        source /usr/share/bash-completion/bash_completion || {
            [[ -f /etc/bash_completion ]] && source /etc/bash_completion
    }
# Source all completions that abide compspec.
# See man bash "Programmable Completion" section.
_completion_loader(){
    source "/etc/bash_completion.d/$1.sh" >/dev/null 2>&1 && return 124
}
[[ "$(type -t complete)" ]] &&
    complete -D -F _completion_loader -o bashdefault -o default

########
# Prompt

# Source git-prompt.sh, which exports all required by 
# Git's conditional prompt function: __git_ps1. See PS1.
[[ "$isBash" ]] && {
    git_prompt="${home}/.git-prompt.sh"
    [[ -f "$git_prompt" ]] && source $git_prompt || {
        git_prompt=/usr/share/git-core/contrib/completion/git-prompt.sh
        [[ -f "$git_prompt" ]] && source $git_prompt
    }
}
unset home

#os="$(os |grep NAME |head -n1 |cut -d'=' -f2 |sed 's/"//g')"
#ver="$(os |grep VERSION_ID |head -n1 |cut -d'=' -f2 |sed 's/"//g')"

########################################################################
##  Must escape and hardcode ANSI code, else fails silently;
##  revealed only on certain keypress, condition, and shell.
##  Example symptom is up-arrow keypress fails to clear prior content.
########################################################################
PS1=''
[[ $isWindows ]] && {
    [[ "$_OS" ]] && {
        PS1='\[\e]0;$_OS\007\]'                                             # Window title
        PS1="$PS1"'\n'                                                      # newline
    } || {
        PS1='\[\e]0;\u@\h\007\]'                                            # Window title
        PS1="$PS1"'\n'                                                      # newline
    }
}
[[ "$_OS" ]] && {
    PS1="$PS1"'\[\e[1;34m\]$_OS'                                            # + $_OS
} || {
    PS1="$PS1"'\[\e[1;34m\]\u\[\e[1;30m\]@\[\e[1;34m\]\h'                   # + $USER@$(hostname)
}
[[ $( type -t __git_ps1 ) ]] && PS1="$PS1"'\[\e[1;97m\]`__git_ps1`'         # + Show "(BRANCH)"            (@ ./.git)
#PS1="$PS1"'\[\e[1;30m\] [$os$ver] [\t] [$SHLVL] [#\j]\[\e[0m\]'            # + [$os$ver] [HH:mm:ss] [$SHLVL] [jobs]
[[ "$isBash" ]] && PS1="$PS1"'\[\e[1;30m\] [\t] [$SHLVL] [#\j]\[\e[0m\]'    # + [HH:mm:ss] [$SHLVL] [jobs] (@ bash)
[[ "$isBash" ]] || PS1="$PS1"'\[\e[1;30m\] [\t] [$SHLVL] \[\e[0m\]'         # + [HH:mm:ss] [$SHLVL]        (@ sh)
PS1="$PS1"'\[\e[1;32m\] \w\[\e[0m\]'                                        # + /full/path/of/pwd
# + newline + prompt + whitespace :
[[ "$(id -u)" == '0' ]] && {
    PS1="$PS1"'\n\[\e[1;91m\]# \[\e[0m\]'                                   # @ root/sudo user : #
} || {                                                                      # @ regular user : ...
    [[ "$isBash" ]] && [[ "${LANG,,}" =~ 'utf-8' ]] && {
        PS1="$PS1"'\n\[\e[1;32m\]'$'\u2629'' \[\e[0m\]'                     # @ Bash : Multi-byte Unicode char
    } || {
        PS1="$PS1"'\n\[\e[1;32m\]$ \[\e[0m\]'                               # Otherwise : $
    }
}

#################################################################
## Using variables for ANSI codes fails silently.
## Imporperly escaped ANSI codes cause terminal errors. 
#################################################################

#     NC='\[\e[0m\]'
#   BLUE='\[\e[1;34m\]'
#  GREEN='\[\e[1;32m\]'
#  WHITE='\[\e[0;37m\]'
#  WHITE='\[\e[1;97m\]'
#   GREY='\[\e[1;30m\]'
# YELLOW='\[\e[1;93m\]'
#    RED='\[\e[1;91m\]'

## Window title
# PS1='\[\e]0;\u@\h\007\]'                           # Window title
# PS1="$PS1"'\n'                                     # newline

# PS1="$PS1""$BLUE\u$GREY@$BLUE\h"                                # $USER@$(hostname)
# [[ $( type -t __git_ps1 ) ]] && PS1="$PS1""$WHITE`__git_ps1`"   # + Show "(BRANCH)"            (@ ./.git)
# #PS1="$PS1""$GREY [$os$ver] [\t] [$SHLVL] [#\j]$NC"             # + [$os$ver] [HH:mm:ss] [$SHLVL] [jobs]
# [[ $isBash ]] && PS1="$PS1""$GREY [\t] [$SHLVL] [#\j]$NC"       # + [HH:mm:ss] [$SHLVL] [jobs] (@ bash)
# [[ ! $isBash ]] && PS1="$PS1""$GREY [\t] [$SHLVL] $NC"          # + [HH:mm:ss] [$SHLVL]        (@ sh)
# PS1="$PS1""$GREEN \w$NC"                                        # + /full/path/of/pwd
# PS1="$PS1"'\n'"$GREEN$prompt $NC"                               # + newline + prompt + whitespace

#[[ $BASH_SOURCE ]] && echo "@ ${BASH_SOURCE##*/}"
[[ "$BASH_SOURCE" ]] && echo "@ $BASH_SOURCE"



