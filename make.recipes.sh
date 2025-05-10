#!/usr/bin/env bash
#######################################################################
# Install bash-shell configuration files for this USER or all users.
# If for all users, then run as root, else requires sudo.
# If run as (sudo) user, then files prefixed: /etc/profile.d/<UID>-*
#######################################################################

sync_bins_user(){
    # Sync .local/bin/ with ~/.local/bin and ~/.bin
    [[ -d .local/bin ]] || return 0
    chmod 0755 .local/bin/*
    find .local/bin -type f -exec /bin/bash -c '
        [[ -d ~/.local/bin ]] && {
            cp -up $1 ~/.local/bin/
            cp -up ~/.local/bin/${1##*/} .local/bin/
        }
        [[ -d ~/.bin ]] && {
            cp -up $1 ~/.bin/
            cp -up ~/.bin/${1##*/} .local/bin/
        }
    ' _ {} \;
    return 0
}

sync_bins_all(){
    # Sync .local/bin/ with /usr/local/bin
    [[ -d .local/bin ]] || return 0
    [[ $(whoami) == root ]] && unset su || su=sudo  
    [[ -d /usr/local/bin ]] ||
        $su mkdir -p /usr/local/bin &&
            $su chown 0:0 /usr/local/bin
    $su chmod 0755 .local/bin/*
    $su find .local/bin -type f -exec /bin/bash -c '
        cp -up $1 /usr/local/bin/
        cp -up /usr/local/bin/${1##*/} .local/bin/
        chown root:root /usr/local/bin/${1##*/}
        [[ $su ]] && chown $(id -u):$(id -g) .local/bin/*
    ' _ {} \;
    return 0
}

user(){
    # Configure current user : UPDATEs ONLY
    find . -maxdepth 1 -type f -iname '.*' -exec cp -up {} ~/ \;
    find functions -type f -iname '*.sh' -exec /bin/bash -c '
        f=${1##*/};cp -up $1 ${0}/.bashrc_${f%%.*}
    ' $HOME {} \;
    [[ "$HAS_WSL" ]] || rm -f ~/.bashrc_win
    [[ "$IS_SUB" ]]  || rm -f ~/.bashrc_sub
    chmod 0644 ~/.profile
    chmod 0644 ~/.bash*
    chmod 0644 ~/.gitignor*
    chmod 0644 ~/.gitconf*
    chmod 0644 ~/.vim*

    [[ -d ~/.local/bin ]] || {
        mkdir -p ~/.local/bin
        cp -p .local/bin/* ~/.local/bin/
    }
    find ~ -maxdepth 1 -type f -iname '.bash*'
    return 0
}

_as(){
    # Configure all users as is current user
    id=$1
    HAS_WSL=$2
    IS_SUB=$3
    git_prompt_dir="${GIT_PROMPT_DIR:-/usr/share/git-core/contrib/completion}"
    rm -f /etc/profile.d/${id}-??-*.sh
    cp ./.bashrc /etc/profile.d/${id}-01-bashrc.sh
    cp ./.bash_functions /etc/profile.d/${id}-02-bash_functions.sh
    find functions -type f -iname '*.sh' -exec /bin/sh -c '
        f=${1##*/};cp -p $1 /etc/profile.d/${0}-${f%%.*}.sh
    ' $id {} \;
    [[ "$HAS_WSL" ]] || rm -f /etc/profile.d/${id}-win.sh
    [[ "$IS_SUB" ]]  || rm -f /etc/profile.d/${id}-sub.sh
    chown root:root /etc/profile.d/${id}-*.sh
    chmod 0644 /etc/profile.d/${id}-*.sh
    mkdir -p /usr/local/bin
    cp -up .local/bin/* /usr/local/bin
    chown -R root:root /usr/local/bin
    chmod 0755 /usr/local/bin
    mkdir -p ${git_prompt_dir}
    cp -up ./.git-prompt.sh ${git_prompt_dir}/git-prompt.sh
    mkdir -p /etc/vim
    cp -up ./.vimrc /etc/vim/vimrc.local
    chown -R root:root /etc/vim
    chmod 0644 /etc/vim/vimrc.local

    ls -hal /etc/profile.d/${id}-*
}

export DECL=$(declare -f _as)

all(){
    # Configure all users
    export id=$(id -u)
    hasSudo=$(type -t sudo)

    [[ ! $hasSudo && "$id" != "0" ]] && {
        echo '=== REQUIREs root user OR sudo'
        return 0
    }
    [[ $hasSudo && "$id" != "0" ]] && {
        sudo /bin/bash -c "$DECL && _as $id $HAS_WSL $IS_SUB"
    }

    [[ "$id" == "0" ]] && {
        _as $id $HAS_WSL $IS_SUB
    } 
    return 0
}

"$@"

