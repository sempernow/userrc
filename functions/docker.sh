# source /etc/profile.d/k8s.sh
##################################################
# Configure bash shell for Docker
##################################################
type -t docker >/dev/null 2>&1 || type -t podman >/dev/null 2>&1 || return
type -t podman >/dev/null 2>&1 && alias docker=podman

[[ "$isBashDockerSourced" ]] && return
set -a # Export all
trap 'set +a' RETURN
#isBashDockerSourced=1

## docker image
di(){ h="$(docker image ls |head -n1)";echo "$h";docker image ls |grep -v REPOSITORY |sort; }
dij(){ # as valid JSON
    type -t jq 2>/dev/null || { echo '  REQUIREs jq';return 0; }
    docker image ls --digests --format "{{json .}}" |jq -Mr . --slurp
}
dit(){ # USAGE: dit [--digests]
    # Must remote "table " from format for actual tab-delimeted fields.
    d(){ docker image ls --format "table {{.ID}}\t{{.Repository}}:{{.Tag}}\t{{.Size}}" $@; }
    echo "$( d |head -n1)";d $@ |grep -v REPOSITORY |sort -t' ' -k2
}

drmi(){ # Remove image(s) per substring ($1), else prune
    [[ "$@" ]] &&
        docker image ls |grep "${@%:*}" |grep "${@#*:}" |gawk '{print $3}' \
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

