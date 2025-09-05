# source /etc/profile.d/win.sh
##############################################
# Configure bash shell @ WSL|Cygwin|GitBash
##############################################
[[ "$hasWSL" ]] || return # See ~/.bashrc

# WSL : Bash on Windows improperly sets `umask` to 0000; should be 0022.
# https://www.turek.dev/post/fix-wsl-file-permissions/
# Only @ WSL @ ConEMU; @ WSLtty, umask is 0022
[[ "$(umask)" == "0000" ]] && umask 0022

[[ "$isBashWinSourced" ]] && return
set -a # Export all
trap 'set +a' RETURN
#isBashWinSourced=1

mkdir -p /c/TEMP
TEMP='/c/TEMP'
for dir in "$TMP" "/tmp" "$TMPDIR" "$TEMP";do
    [[ -d "$dir" ]] && TMPDIR="$dir"
done;TMP=$TMPDIR;TEMP=$TMPDIR

# Win => POSIX
unset _PREFIX
unset _USERPROFILE
[[ ! "$USERNAME" ]] && USERNAME="$USER"
[[ ! "$USER" ]] && USER="$USERNAME"
[[ "$USERPROFILE" ]] && {
    [[ "$( type -t cygpath )" ]] &&
        _USERPROFILE="$( cygpath -au "$USERPROFILE" )"
} || {
    [[ "$( type -t cmd.exe )" ]] && {
        [[ "$USERNAME" == 'root' ]] &&
            USERPROFILE=/ ||
            USERPROFILE="/$(echo "$(cmd.exe /c "set USERPROFILE")" |awk -F= '{print $2}' |sed 's,\\,/,g' |sed 's,:,,g' |sed 's,^C,c,g')"
        [[ "$USERPROFILE" ]] &&
            _USERPROFILE="$USERPROFILE"
    }
}
_HOME="$HOME" # set to %HOME% if Cygwin|Git-for-Windows|MINGW64|MSYS

# paths @ HOME
_ETC_ARCHIVES_FOLDER="${_HOME}/etc.archives"
[[ -d ~/.bin ]] && _SCRIPTS_FOLDER=~/.bin || _SCRIPTS_FOLDER="${_HOME}/etc/scripts/bash"

# --------------------------
#  PER PLATFORM 
# --------------------------
# @ cygwin|msys
[[ "$OSTYPE" == 'cygwin' || "$OSTYPE" == 'msys' ]] && {
    # Path prefix @ mounted volumes; per /etc/fstab
    # REFs: https://cygwin.com/cygwin-ug-net/using.html#mount-table
    [[ "$OSTYPE" == 'msys' ]] && _PREFIX='' || _PREFIX=''
    _USERPROFILE="${_PREFIX}${_USERPROFILE}"
    # Fix xclip issues @ WSL/WSL2 : Requires VcXsrv X Server : choco install vcxsrv -y
    DISPLAY=:0 # @ VcXsrv running
    XAUTHORITY="${_HOME}/.Xauthority"
    XDG_CURRENT_DESKTOP=X-Cygwin
    XDG_MENU_PREFIX=xwin-
    # Local storage paths
    [[ "$VERSIONING" ]] && _VERSIONING="$(cygpath -au "$VERSIONING")"
    _UNREG_FOLDER="${_PREFIX}/c/Program Files/_unregistered"
    _MUCK_REF_FOLDER="$_HOME/.config/muck"
    _REFs_LOCAL="${_PREFIX}$(cygpath -au 'D:\1 Data\IT')"
    _PRJs_LOCAL="${_PREFIX}$(cygpath -au 'D:\1 Data\Projects')"
    _BASH_HELP_PATH="${_PREFIX}$(cygpath -au 'D:\1 Data\IT\Programming\Shell\bash')"
    _GIT_REPO="${_PREFIX}$(cygpath -au "$GITREPO")"
    _SCRATCH="${_PREFIX}$(cygpath -au "$SCRATCH")"

    # Local|Host machine node + python3 dev. env.
    [[ "$_USERPROFILE" ]] && {
        [[ "$PATH" =~ /npm ]] && {
            p1="${_PREFIX}$(cygpath -au "$USERPROFILE")/AppData/Roaming/npm"
            p2="${_PREFIX}/c/Program Files/nodejs"
            [[ -d "$p1" ]] && PATH="$p1:$PATH"
            [[ -d "$p2" ]] && PATH="$p2:$PATH"
        }
        [[ "$PATH" =~ /Python ]] && {
            p1="${_PREFIX}${_USERPROFILE}/AppData/Local/Programs/Python/Python36-32/Scripts"
            p2="${_PREFIX}${_USERPROFILE}/AppData/Local/Programs/Python/Python36-32"
            [[ -d "$p1" ]] && PATH="$PATH:$p1"
            [[ -d "$p2" ]] && PATH="$PATH:$p2"
        }
    }
    #_STAGING_FOLDER="/smb/staging" # See /etc/fstab
    true
} || {
# @ linux-gnu

    # @ brew
    [[ "$PATH" =~ /linuxbrew ]] && {
        p1="/home/linuxbrew/.linuxbrew/bin"
        [[ -d "$p1" ]] && PATH="$PATH:$p1"
    }

    # @ (some) WSL
    [[ ! -d "${_HOME}" && -d "/mnt${_HOME}" ]] && {
        _PREFIX="/mnt"
        _HOME="${_PREFIX}${_HOME}"
        _USERPROFILE="${_PREFIX}${_USERPROFILE}"
    }
    _UNREG_FOLDER="$_HOME/_unregistered"
    _MUCK_REF_FOLDER="$_HOME/.config/muck"
    # @ WSL
    [[ $(type -t notepad.exe) ]] && {
        _REFs_LOCAL="${_PREFIX}/d/1 Data/IT"
        _PRJs_LOCAL="${_PREFIX}/d/1 Data/Projects"
        _BASH_HELP_PATH="${_PREFIX}/d/1 Data/IT/Programming/Shell/bash"
    } || {
        _REFs_LOCAL="$_HOME/etc/REFs"
        _PRJs_LOCAL="$_HOME/etc/PRJs"
        _BASH_HELP_PATH="$_HOME/etc/REFs"
    }
    # LAN mount(s)
    #_STAGING_FOLDER="/media/SMB/staging"
    #_STAGING_FOLDER="/smb/staging"
    # Golang Env.
    [[ "$GOROOT" ]] || GOROOT='/usr/local/go'
    # BUG :: hidden chars in USERPROFILE & _USERPROFILE
    for dir in "${_HOME}/go" ~/go '/go' "/c/Users/${USER^^}/go" '/c/Users/X1/go' "${USERPROFILE}/go"
    do
        [[ -d "$dir" ]] && GOPATH="$dir"
    done; 
    [[ -d "$GOROOT" && -d "$GOPATH" && -d "$GOROOT/bin" ]] &&
        GOBIN="$GOROOT/bin" && PATH="$PATH:$GOBIN"

    # OS Distro/Version
    [[ -f /etc/lsb-release ]] && {
        _OS=$( grep ID /etc/lsb-release ); _OS="${_OS#*=}"
    } || {
        [[ -f /etc/debian_version ]] && _OS="Debian"
    }
    # Dev Environment 
    # for X-Server (MobaXterm|VcXsrv @ WSL)
    DISPLAY=:0  # HOST:TERMINAL
    # Docker-for-Windows Server listening @
    # Comment out @ Docker Desktop configured for WSL 2, else remove comment
    #[[ $USER != 'vagrant' ]] && DOCKER_HOST=tcp://0.0.0.0:2375
}

_CYGDRIVE="$_PREFIX" # Used @ local bash scripts, e.g., cygpath, ffmpeg

[[ "$_STAGING_FOLDER" ]] && {
    _REFs_STAGING="${_STAGING_FOLDER}/etc/REFs"
    _PRJs_STAGING="${_STAGING_FOLDER}/etc/PRJs"
}

[[ "$_SCRIPTS_FOLDER" ]] && [[ "$PATH" =~ "$_SCRIPTS_FOLDER" ]] &&
    PATH="$PATH:$_SCRIPTS_FOLDER"

# PS1 ref @ https://ss64.com/bash/syntax-prompt.html
[[ "$_OS" ]] || _OS="$WSL_DISTRO_NAME"
[[ "$MSYSTEM" ]] || MSYSTEM="${OSTYPE^^}"
[[ "$_OS" ]] || _OS="$MSYSTEM"

# Normalize SHLVL for WSL @ ConEMU
[[ "$OSTYPE" == 'linux-gnu' && "$ConEmuPID" ]] && SHLVL=$(( $SHLVL - 2 ))

# make @ Git-for-Windows 
[[ "$OSTYPE" == 'msys' ]] && alias make=/c/ProgramData/chocolatey/bin/make.exe
_ARCHIVE_DOT_FILES=1 # Set to archive dot file
is_hex32() {
    # PARAMs: STR
    # $? returns 1 if $1 hex-32 string, else 0
    [[ "$1" ]] || return 0
    [[ ${#1} -eq 32 ]] || return 0
    [[ "$1" != *[!0-9A-Fa-f]* ]] || return 0

    return 1
}
isinteger() {
    # PARAMs: STR
    # stdout: $1 if int, else nul
    [[ -z "${1//[0-9]}" ]] && printf "$1"
}
substr() {
    # PARAMs: SUBSTR STR
    # stdout: $1 if in $2, else nul
    [[ "${2/$1}" != "$2" ]] && echo "$1"
}
bashprofile()   { openedit "${_HOME}/.profile";openedit "${_HOME}/.bash_profile"; }
bashfunctions() { openedit "${_HOME}/.bash_functions";openedit "${_HOME}/.bash_functions2"; }
bashrc()    { openedit "${_HOME}/.bashrc"; }
bashrcX()   { openedit "${_HOME}/.bashrcX"; }
syntax()    { openedit "${_BASH_HELP_PATH}/REF.bash.syntax.sh"; }
commands()  { openedit "${_BASH_HELP_PATH}/REF.bash.commands.sh"; }
win2posix() { printf "%s" "$@" |sed 's,\\,/,g' |sed 's,:,,'; }
#urlencode(){ printf "%s\n" "$@" |sed 's,\\,/,g' |sed 's, ,%20,g'; }
islink() { [[ -L "$@" && -d "$@" ]] && echo "SYMLINKD"; }
isASCII() {
    # ARGs: FILE-PATH
    # stdout: '1' if ASCII, null if binary
    [[ -f "$@" ]] && {
        [[ $(file -b "$@" |grep -i 'ASCII') ]] && echo '1' || true
    } || {
        echo  "REQUIREs input file; stdout '1' if ASCII; null if binary"
        return 99
    }
}
isDOS() {
    # ARGs: FILE-PATH
    # stdout: '1' if DOS, null if UNIX
    # companion script: ~/.bin/dos2unix
    REQUIREs isASCII #dos2unix
    [[ -f "$@" ]] && {
        [[ "$(isASCII "$@")" ]] || return 0
        #dos2unix < "$@" |cmp -s - "$@"
        #(( $? )) && echo '1' || true
        [[ "$(file "$@" |grep 'CRLF')" ]] && echo '1' || true
    } || {
        echo  "REQUIREs input file; stdout '1' if DOS; null if UNIX"
        return 99
    }
}
isdosall() { # companion script: ~/.bin/dos2unixall
    find . -maxdepth 1 -type f -execdir /bin/bash -c '[[ $( isDOS "$@") ]] && printf "%s\t%s\n" "${@##*/}" "... is DOS"' _ "{}" \;
}
SVN() {
    # ARGs: FOLDER|GIT{URL-of-GitHub-repository-subfolder}
    # svn wrapper; download/clone a target folder of any GitHub repository
    REQUIREs errMSG svn
    # if neither keyword @ $1, then simply pass $@ to native svn, and return
    [[ "${1,,}" != 'folder' && "${1,,}" != 'git' ]] && { svn "$@"; true; } || {
        # if keyworkd @ $1, but bad url-param @ $2, then inform and return
        [[ -n "$2" ]] || { errMSG 'Valid URL expected @ $2'; return 99; }
        # else execute native 'svn checkout <URL>' command,
        # but modify URL: 'tree/master' replaced with 'trunk'
        
        svn checkout ${2/'tree/master'/'trunk'}
    }
}
h() {
    # ARGs: COMMAND
    # Superpowered 'help'; tries all bash methods
    case $(type -t "$1") in
        alias) alias "$1";;
        keyword) # goto 'SHELL GRAMMAR' @ man bash
            LESS="$LESS+/^SHELL GRAMMAR" man bash;;
        function) type "$1";;
        builtin) help "$1";;
        file) # try help, then man page
            "$1" --help ||
            man -S 1,8 "$1" ||  man "$1";;
            # [[ "$( type -t xdg-open )" ]] && xdg-open "http://www.google.com/search?q=$x"
        *) man "$1";;
    esac
}

_store_per_platform() { # ARGs: [OSTYPE]; defaults to current platform per $OSTYPE
    [[ ! -d "$_HOME" ]] && { errMSG '_HOME Env.Var. is unset.' 1>&2 ; return 99; }
    [[ "$1" ]] && _ostype="${1,,}" || _ostype="$OSTYPE"
    #_store="$_HOME/etc/platforms/$_ostype/HOME"
    _store="$_HOME/etc/platforms/all/HOME"
    [[ -d "$_store" ]] && {
        echo "$_store"
    } || {
        errMSG "The store for '$_ostype' platform does NOT EXIST." 1>&2
        return 99
    }
}
restoreroot() {
    # ARGs: [OSTYPE] ; defaults to current platform per $OSTYPE
    # restore, to HOME, the per-platform store of certain root dot-files and dot-folders
    # (See "storeroot" function.)
    echo "@ $FUNCNAME"
    _store="$( _store_per_platform $1 )" ; (( $? )) && return 99
    find "$_store" -maxdepth 1 -type f -iname '*.tgz' -exec tar -xaf "{}" -C "$_HOME" \;
    return
}
script_info() {(
    # ARGs: SCRIPT-PATH
    # stdout: script header/info [delimited per convention]
    clear ; echo "INFO @ ${@##*/}" ; (( count = 0 ))
    while IFS='' read -r line
    do  # print all lines between the two identical delimiters
        [[ "${line:0:17}" == '# ---------------' ]] && (( count += 1 ))
        [[ $count -gt 0 ]] && echo "$line"
        [[ $count -gt 1 ]] && break
    done < "$@"
)}
flagupdate() {
    # PARAMs: SOURCE-PATH REF-PATH
    # Utility for 'store' and 'storage' scripts
    # $? returns 0 if ref is up-to-date with source, 
    # or source not exist, else 1|2|86|99
    REQUIREs newest
    [[ "$2" ]]    || return 99 # REF not provided
    [[ -e "$1" ]] || return 0  # SOURCE not exist
    [[ -e "$2" ]] || return 2  # REF not exist

    [[ "$(newest "$1")" -nt "$2" ]] && return 1 || return 0

    return 86  # should never happen 
}

# User specific environment and startup programs
[[ "$PATH" =~ "$HOME/.bin:" ]] || PATH="$HOME/.bin:$PATH"

# Get/set top-level shell PID [ps @ Cygwin prefixes 1st collumn w/ 'I' ]
_PID_1xSHELL=$(ps |grep 'bash' |sort -k 7 |awk '{print $1;}' |head -n 1)
# handle Cygwin; @ ps 'bash' line, collumn prefixed with 'I'
[[ "$( isinteger $_PID_1xSHELL )" ]] || _PID_1xSHELL=$(ps |grep 'bash' |sort -k 7 |awk '{print $2;}' |head -n 1)

## End here if not interactive
[[ -z "$PS1" ]] && return 0

#[[ "$USERPROFILE" ]] || errMSG "FAILed @ USERPROFILE"

[[ "$isBash" && "$hasWSL" ]] && {
    # @ WSL 2 : Host IP is NOT localhost : some apps fail if DISPLAY not reset:
    ## STDOUT of this wsl.exe statement includes a null byte. (Thank Microsoft.)
    ## This named-pipe scheme handles that, else warning text persists (@ STDOUT) regardless.
    set +o posix          # if syntax not POSIX, abide other
    mkfifo p1
    wsl.exe -l -v >p1 & >/dev/null 2>&1
    [[ $(cat <p1 |tr -d '\000' |grep ${_OS} |awk '{print $NF}' |grep 2) ]] && {
        # Reset only at WSL 2 terminal
        #export DISPLAY='172.31.16.1:0.0'
        # @ Win10
        #export DISPLAY=$(grep nameserver /etc/resolv.conf |awk '{print $2}'):0.0
        # @ Win11 + VcXsrv running : Fix for xclip @ passgo 
        DISPLAY=:0
    }
    rm p1
}

[[ "$BASH_SOURCE" ]] && echo "@ $BASH_SOURCE"

