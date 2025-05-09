# source /etc/profile.d/git.sh
################################
# Configure bash shell for Git
################################
[[ "$(type -t git)" ]] || return
[[ "$isBashGitSourced" ]] && return

git_bash_completion=/usr/share/bash-completion/completions/git
[[ -f $git_bash_completion ]] && source $git_bash_completion

set -a # Export all
trap 'set +a' RETURN
#isBashGitSourced=1

alias gcfg='git config -l'
gi(){
    br=${1:-master}
    [[ -d .git ]] && return 1
    acct=$(git config user.account)
    [[ $acct ]] || return 2
    repo=$(pwd);repo=${repo##*/}
    git init
    git branch -M $br
    git remote add origin github.com:/$acct/$repo.git
    gc
    git push -u origin $br
}
ga(){ git add . ; git status; }
gb(){ git branch --all;echo;git remote -v; }
gbd(){
    [[ "$1" ]] || return 90
    [[ "$(git branch --all |grep $1)" ]] || return 91
    git branch -D $1                # Local
    git push origin --delete $1     # Remote
}
gc(){ # commit -m [MSG]
    newest(){
        TZ=Zulu find . -type f ! -path '*/.git/*' ! -iname '*.log' ! -iname 'LOG.*' -printf '%T+ %P @ %TY-%Tm-%TdT%TH:%TMZ\n' \
            |sort -r |head -n 1 |cut -d' ' -f2-
    }
    export -f newest
    [[ "$@" ]] && _m="$@" || _m="$(newest)"
    git add -u && git add . && git commit -m "$_m" && gl
    true
}
gch(){ # Checkout else create branch $1 else create branch HH.MM
    [[ "$@" ]] && _b="$@" || _b="$(date '+%H.%M')"
    [[ "$(git branch |grep "$_b")" ]] && git checkout "$_b" || git checkout -b "$_b"
}
gl(){ # List all commits, one line per, or n ($1) showing changes (stat) per 
    clear && [[ "$1" ]] && git log --stat -n $1 || git log --oneline -n 10
}
gpf(){ git push --force-with-lease; } # force required after rebase
gr(){
    count_commits=$(( $( git rev-list --count HEAD ) - 1 ))
    (( "$count_commits" < 2 )) && {
        gl; printf "\n%s\n" 'Not enough commits to squash.'
    } || {
        echo "
            Interactive rebase, squashing $count_commits (max) commits.
            
            Launches default editor. Replace all 'pick' with 's',
            except 1st listed (max squash).
            Subsequent push may require "'`git push --force`.'"
            Abort (on fail): "'`git rebase --abort` .'

        git rebase -i HEAD~$count_commits
    }
}
grs(){
    echo "
        Reset, squash everything regardless. Preserve only the newest commit.
        Subsequent push may require "'`git push --force`.'

    count_commits=$(( $( git rev-list --count HEAD ) - 1 ))
    git reset --soft HEAD~$count_commits
}
gs(){ git status; }

## End here if not interactive
[[ -z "$PS1" ]] && return 0

[[ "$BASH_SOURCE" ]] && echo "@ $BASH_SOURCE"

