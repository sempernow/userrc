# source /etc/profile.d/k8s.sh
##################################################
# Configure bash shell for kubectl|minikube|helm
##################################################
[[ "$isBashK8sSourced" ]] && return
#isBashK8sSourced=1
unset flag_any_k8s

[[ $(type -t ctr) ]] && {
    ctr(){ command ctr -n k8s.io "$@"; }
    export -f ctr
}

[[ $(type -t crictl) ]] && {
    flag_any_k8s=1
    set -a
    pods(){ echo "$(sudo crictl pods |grep -v STATE |awk '{print $1}')"; }
    containers(){ echo "$(sudo crictl ps |grep -v STATE |awk '{print $1}')"; }
    images(){ echo "$(sudo crictl images |grep -v STATE |awk '{print $1}')"; }
    set +a;set +o posix
    #source <(sudo crictl completion)
}

[[ $(type -t cilium) ]] && {
    flag_any_k8s=1
    set +a;set +o posix
    source <(cilium completion bash)
}

[[ $(type -t kubectl) ]] && {
    flag_any_k8s=1
    set -a
    all='deploy,ds,sts,pod,svc,ep,ingress,cm,secret,pvc,pv'
    k(){ kubectl "$@"; }
    set +a;set +o posix
    source <(kubectl completion bash)
    # k completion
    complete -o default -F __start_kubectl k

    # krew : https://krew.sigs.k8s.io/docs/user-guide/setup/install/
    [[ -d "$HOME/.krew/bin" ]] && {
        [[ $PATH =~ "$HOME/.krew/bin:" ]] ||
            PATH="$HOME/.krew/bin:$PATH"
    }

    # Get/Set kubectl namespace : USAGE: kn [NAMESPACE]
    kn (){
        all(){ kubectl get ns --no-headers | cut -d' ' -f1; }
        [[ -n $1 ]] && {
            [[ -n $(all |grep $1) ]] &&
                kubectl config set-context --current --namespace $1 &&
                    kn
        }
        [[ -n $1 ]] || {
            ctx="$(kubectl config view -o jsonpath='{.current-context}')"
            [[ -n $ctx ]] || return 11
            ns="$(kubectl config view -o jsonpath='{.contexts[?(@.name=="'$ctx'")].context.namespace}')"
            [[ -n $ns ]] || return 12
            all |command grep --color $ns
            all |command grep -v $ns
        }
    }

    # Get/Set kubectl context : USAGE: kx [CONTEXT_NAME]
    kx() { 
        [[ $1 ]] && {
            kubectl config use-context $1
        } || {
            #kubectl config current-context
            kubectl config get-contexts
        }
    }

    # Get/Set cluster's default StorageClass 
    # (minikube reverts to "standard" per `minikube start`)
    ksc(){
        [[ $1 ]] && {
            default=$(kubectl get sc |grep default |awk '{print $1}')
            [[ $default ]] && { 
                ## If current default exists, then unset it
                kubectl patch sc $default -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
            }
            ## Set default to $1
            kubectl patch sc $1 -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
        }
        kubectl get sc
    }

    # Get workloads per node
    kw(){
        kubectl get nodes -o jsonpath='{.items[*].metadata.name}' \
            |xargs printf "%s\n" \
            |xargs -IX /bin/bash -c '
                echo === $1 : $(k get pod -o wide |grep $1 |wc -l)/$(k get pod -A -o wide |grep $1 |wc -l) 
                kubectl get pod -o wide |grep $1
            ' _ X
            printf "\n%s\n" "$(k get pod |grep -v NAME |wc -l)/$(k get pod -A |grep -v NAME |wc -l) @ $(kn |head -n1)"
    }

    psk(){
        # Print entire command statement of k8s process(es).
        # ARGs: [command(Default: all)]
        k8s='
            containerd
            dockerd
            etcd
            kubelet
            kube-apiserver
            kube-controller-manager
            kube-scheduler
            kube-proxy
        '
        _ps(){
            [[ "$1" ]] || exit 1
            echo @ $1
            ps -ax -o command |grep -- "$1 " |tr ' ' '\n' \
                |grep -- -- |grep -v color |grep -v grep
        }
        export -f _ps
        [[ $1 ]] && _ps $1 || echo $k8s |xargs -n 1 /bin/bash -c '_ps "$@"' _
    }

}

[[ $(type -t minikube) ]] && {
    flag_any_k8s=1
    set -a
    # d2m : Configure host's Docker client (docker) to Minikube's Docker server.
    d2m(){ [[ $(echo $DOCKER_HOST) ]] || eval $(minikube -p minikube docker-env); }

    mdns() { 
        # TODO : Find a better method (Perhaps resolve @ /etc/hosts)
        # If Minikube's ingress-dns addon is enabled, 
        # then add Minikube's IP as a nameserver for this machine's DNS resolver (idempotently).
        # See manual page /etc/resolv.conf(5)
        [[ $(cat /etc/resolv.conf |grep $(minikube ip)) ]] || {
            [[ $(minikube addons list |grep ingress-dns) && $(minikube ip |grep 192.168) ]] && {
                printf "%s\n%s\n" "nameserver $(minikube ip)" "options rotate" \
                    |sudo tee -a /etc/resolv.conf
            }
        }
    }
    set +a;set +o posix # Abide non-POSIX syntax 
    source <(minikube completion bash)
}

#[[ $(type -t k3s) ]] && sudo k3s kubectl get pod -o jsonpath='{.}' && {
#    flag_any_k8s=1
#    set +a;set +o posix # Abide non-POSIX syntax 
#    source <(sudo k3s completion bash)
#    k get svc -o jsonpath='{.}' 2>/dev/null || alias k='sudo k3s kubectl'
#}

# Helm : Capture all dependencies of a chart
# Save all Docker-image dependencies of a chart 
# using three helper functions: hdi (list), hvi (validate), dis (save).
#   hdi $extracted  # $extracted is the extracted-chart folder.
#   hvi hdi@${extracted}.log
#   dis hvi@hdi@${extracted}.log
[[ $(type -t helm) && $(type -t docker) ]] && {
    flag_any_k8s=1
    set -a
    # List all Docker images of an extracted Helm chart $1 (directory).
    ###############################################################
    # UPDATE: THIS FAILs to capture all. 
    ###############################################################
    hdi(){
        [[ -d $1 ]] && {
            helm template "$@" \
                |grep image: \
                |sed '/^#/d' \
                |awk '{print $2}' \
                |awk -F '@' '{print $1}' \
                |tr -d '"' \
                |sort -u |tee ${FUNCNAME}@${1##*/}.log
        } || {
            echo "=== USAGE : $FUNCNAME [All options required by helm install] PATH_TO_CHART_FOLDER"
        }
    }

    # Validate all Docker images listed in file $1 against those in Docker's cache
    hvi(){
        [[ -f $1 ]] && {
            [[ -n $(echo $DOCKER_HOST) ]] || eval $(minikube -p minikube docker-env)
            while read -r
            do docker image ls --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" |grep ${REPLY##*/}
            done < $1 |tee ${FUNCNAME}@${1##*/}
        } || {
            echo "=== USAGE : $FUNCNAME PATH_TO_IMAGES_LIST_FILE (E.g., hdi@CHART-VER.log)"
        }
    }

    # Perform docker save and gzip (*.tar.gz) on all images listed in file $1.
    # To load a saved image, use docker load, *not* docker import.
    dis(){
        [[ -f $1 ]] && {
        while read -r
        do 
            img="$(echo $REPLY |awk '{print $1}')"
            out="$(echo $img |sed 's,/,.,g' |sed 's,:,_,g').tar.gz"
            [[ -f $out ]] || {
                docker save $img |gzip -c > $out
                printf "%s\t%s\n" $img $out |tee -a ${FUNCNAME}@${1##*/}
            }
        done < $1
        } || {
            echo "=== USAGE : $FUNCNAME PATH_TO_IMAGES_LIST_FILE (E.g., hvi@hdi@CHART-VER.log)"
        }
    }
    set +a
}

## End here if not interactive
[[ -z "$PS1" ]] && return 0

[[ $flag_any_k8s ]] && [[ "$BASH_SOURCE" ]] && echo "@ $BASH_SOURCE"
unset flag_any_k8s

