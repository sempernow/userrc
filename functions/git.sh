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
    git init -b $br
    git remote add origin github.com:/$acct/$repo.git
    gc
    git push -u origin $br
}
gls(){ git ls-tree -r HEAD --name-only; }
gs(){ git status; }
glo(){ git log --oneline -n ${1:-10}; }
gl(){ glo "$@"; }
glp(){ git log --oneline -p -n ${1:-1}; }
gls(){ git log --oneline --stat -n ${1:-1}; }
glg(){ git log --oneline --decorate --all --graph; }
gd(){ git diff HEAD; }
gdo(){ git diff origin; }
gdos(){ git diff origin --stat; }
gb(){ git branch --all;echo;git remote -v; }
gbd(){
    [[ "$1" ]] || return 90
    [[ "$(git branch --all |grep $1)" ]] || return 91
    git branch -D $1                # Local
    git push origin --delete $1     # Remote
}
gch(){ # Checkout else create branch $1 else create branch HH.MM
    [[ "$@" ]] && _b="$@" || _b="$(date '+%H.%M')"
    [[ "$(git branch |grep "$_b")" ]] && git checkout "$_b" || git checkout -b "$_b"
}
ga(){ git add -u && git add . ; git status; }
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
gpf(){ git push --force-with-lease; } # force required after rebase
gr(){
    count_commits=$(( $( git rev-list --count HEAD ) - 1 ))
    (( "$count_commits" < 2 )) && {
        gl; printf "\n%s\n" 'Not enough commits to squash.'
    } || {
        echo "
            Interactive rebase, squashing $count_commits (max) commits.
            
            Launches editor.
            Replace all 'pick' with 's' (squash, but keep messages),
            else 'f' (fix; squash sans),
            except 1st (oldest) listed (for max squash).
            Subsequent push probably requires:
            "'`git push --force-with-lease`.'"
            Else abort by "'`git rebase --abort`.'

        git rebase -i HEAD~$count_commits
    }
}
grs(){
    glo
    read -p "⚠️ Squash ALL commits to keep only newest? [y/N] " -n 1 -r REPLY
    echo 
    if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
        echo -e "\n🔚 Aborting ...\n"
        
        return 0
    else
        if [[ -n $(git status --porcelain) ]]; then
            echo -e "\n❌ NO : Working directory is dirty. Commit or stash your changes first.\n" >&2
            git status
            
            return 99
        fi
        echo -e "\n⌛ Squashing ...\n"

        git reset $(git commit-tree HEAD^{tree} -m "$(git log -1 --pretty=%B)")
    fi
}

## End here if not interactive
[[ -z "$PS1" ]] && return 0

[[ "$BASH_SOURCE" ]] && echo "@ $BASH_SOURCE"

