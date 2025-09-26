# source /etc/profile.d/k8s.sh
#######################################################
# Configure bash shell for docker else podman if exist
#######################################################
type -t docker >/dev/null 2>&1 ||
    type -t podman >/dev/null 2>&1 ||
        return

type -t podman >/dev/null 2>&1 && {
    type -t docker >/dev/null 2>&1 ||
        alias docker=podman
}

[[ "$isBashDockerSourced" ]] && return
set -a # Export all
trap 'set +a' RETURN
#isBashDockerSourced=1

## docker image
di(){ 
    [[ $2 =~ 'digest' ]] && digest=--digests || unset digest
    [[ $1 =~ '--digest' ]] && digest=--digests && set --
    d(){ docker image ls $digest; }
    d |head -n1
    [[ $1 ]] && d |grep $1 |grep -v REPOSITORY |sort
    [[ $1 ]] || d |grep -v REPOSITORY |sort
}
dij(){ # as valid JSON
    type -t jq >/dev/null 2>&1 || { echo '  REQUIREs jq';return 0; }
    d(){
        _dij(){ docker image ls --digests --format "{{json .}}"; }
        [[ $1 ]] && _dij |grep $1
        [[ $1 ]] || _dij
    }
    d "$1" |jq -Mr . --slurp |
        jq -Mr '.[] | {image: (.Repository + ":" + .Tag), size: .Size, built: .CreatedAt, age: .CreatedSince, digest:.Digest}' |
            jq . --slurp
}
dit(){ 
    [[ $2 =~ 'digest' ]] && digest=--digests || unset digest
    [[ $1 =~ '--digest' ]] && digest=--digests && set --
    d(){ docker image ls $digest  --format "table {{.ID}}\t{{.Repository}}:{{.Tag}}\t{{.Size}}"; }
    d |head -n1
    [[ $1 ]] && d |grep $1 |grep -v REPOSITORY |sort -t' ' -k2
    [[ $1 ]] || d |grep -v REPOSITORY |sort -t' ' -k2
}
dii(){
    type -t yq >/dev/null 2>&1 || {
        echo REQUIREs yq
        return 1    
    }
    [[ $1 ]] || {
        echo "USAGE : $FUNCNAME <IMAGE>"
        return 2
    }
    docker image inspect $1 |yq eval -P -o yaml |yq '.[] | (.RepoTags,.RepoDigests,.Config)'
}
drmi(){ # Remove image(s) per substring ($1), else prune
    [[ "$1" ]] &&
        docker image ls |grep "${1%:*}" |grep "${@#*:}" |gawk '{print $3}' \
            |xargs docker image rm -f ||
                docker image prune -f
}

## docker container
alias dps='docker container ps --format "table {{.ID}}  {{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}"'
alias dpsa='docker ps -a --format "table {{.ID}}  {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"'
dstart(){ [[ "$@" ]] && docker container ls -a |grep "$@" |gawk 'NR == 1 {print $1}' |xargs docker container start; }
dstop(){ [[ "$@" ]] && docker container ls    |grep "$@" |gawk '{print $1}' |xargs docker container stop; }
drm(){ [[ "$@" ]] && docker container ls -a |grep "$@" |gawk '{print $1}' |xargs docker container rm -f; }
## docker network
dnetl(){ docker network ls $@; }
alias dnet=dnetl
dneti(){ docker network inspect $@; }
dnetp(){ docker network prune -f; }
## docker volume
dvl(){ docker volume ls $@; }
dvi(){ docker volume inspect $(docker volume ls -q) |jq -rM '.[] | .Name, .CreatedAt'; }
dvp(){ docker volume prune -f; }
## docker exec
dex(){
    [[ "$1" ]] && {
        ctnr=$(docker container ls --filter name=$1 -q)
        [[ $ctnr ]] || ctnr=$(docker container ls |grep $1 |cut -d' ' -f1 |head -n1)
        [[ $ctnr ]] || { type dex;return; }
        shift;cmd=$1;shift
        docker exec -it $ctnr ${cmd:-sh} $@
        return 0
    } || {
        type dex
    }
}
## docker stats
dstats(){ 
    [[ "$1" ]] && _no_stream='--no-stream' || unset _no_stream
    docker stats $_no_stream --format 'table {{.ID}}  {{.Name}}\t{{.CPUPerc}}  {{.MemUsage}}\t{{.MemPerc}}  {{.NetIO}}\t{{.BlockIO}}\t{{.PIDs}}'
}

## End here if not interactive
[[ -z "$PS1" ]] && return 0

[[ "$BASH_SOURCE" ]] && echo "@ $BASH_SOURCE"

