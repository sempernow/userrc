# source .bash_functions || source /etc/profile.d/${USER}-02-bash_functions.sh

# End here if functions already exist (run once)
#[[ "$(type -t now)" ]] && return

# End here if previously sourced unless from /etc/profile.d/
[[ "$BASH_SOURCE" =~ "/etc/profile.d" ]] || {
    [[ "$isBashFunctionsSourced" ]] && return
}
set -a # Export all
trap 'set +a' RETURN
#isBashFunctionsSourced=1

[[ "$_PID_1xSHELL" ]] ||
    _PID_1xSHELL=$(ps |grep 'bash' |sort -k 7 |awk '{print $1;}' |head -n 1)

########
# String
trim(){ local x="${@##+([[:space:]])}"; x="${x%%+([[:space:]])}"; printf "%s" "$x"; }

######
# Date

# For EST (UTC-05:00) that ignores Daylight Savings Time (UTC-04:00):
#TZ='America/New_York'

nist(){ cat </dev/tcp/time.nist.gov/13; }
today(){
    # YYY-MM-DD
    t="$(date "+%F")";echo "$t"
    #[[ ! "$1" ]] && { REQUIREs putclip ; putclip "$t"; }
    #[[ ! "$1" ]] && { [[ $(type -t putclip) ]] && putclip "$t"; }
}
now(){
    # HH.mm.ss
    t="$(date "+%H.%M.%S")";echo "$t"
    #[[ ! "$1" ]] && { [[ $(type -t putclip) ]] && putclip "$t"; }
}
todaynow(){
    # YYY-MM-DD_HH.mm.ss
    t="$(date "+%F_%H.%M.%S")";echo "$t"
    #[[ ! "$1" ]] && { [[ $(type -t putclip) ]] && putclip "$t"; }
}

utc(){
    # YYY-MM-DDTHH.mm.ss [TZ]
    t="$(date "+%Y-%m-%dT%H:%M:%S [%Z]")";echo "$t"
    #[[ ! "$1" ]] && { [[ $(type -t putclip) ]] && putclip "$t"; }
}
utco(){
    # YYY-MM-DDTHH.mm.ss-HHHH
    #t="$(date "+%Y-%m-%dT%H:%M:%S%z")";echo "$t"
    # YYY-MM-DDTHH.mm.ss-HH:HH
    t="$(date --iso-8601=s)";echo "$t"
    #[[ ! "$1" ]] && { [[ $(type -t putclip) ]] && putclip "$t"; }
}
gmt(){
    # YYY-MM-DDTHH.mm.ssZ
    t="$(date -u "+%Y-%m-%dT%H:%M:%SZ")";echo "$t"
    #[[ ! "$1" ]] && { [[ $(type -t putclip) ]] && putclip "$t"; }
}
gmto(){
    # YYY-MM-DDTHH.mm.ss+0000
    #t="$(date -u "+%Y-%m-%dT%H:%M:%S%z")";echo "$t"
    # YYY-MM-DDTHH.mm.ss+00:00
    t="$(date -u --iso-8601=s)";echo "$t"
    #[[ ! "$1" ]] && { [[ $(type -t putclip) ]] && putclip "$t"; }
}

zulu(){ gmt "$@"; }
utcz(){ gmt "$@"; }

iso(){
    # YYY-MM-DDTHH.mm.ss+/-HH:mm
    t="$(date --iso-8601=seconds)";echo "$t"
    #[[ ! "$1" ]] && { [[ $(type -t putclip) ]] && putclip "$t"; }
}
isoz(){
    # YYY-MM-DDTHH.mm.ss+00:00
    t="$(date -u --iso-8601=seconds)";echo "$t"
    #[[ ! "$1" ]] && { [[ $(type -t putclip) ]] && putclip "$t"; }
}

####
# FS

dft(){ df -hT |grep -e Type -e ${1:-xfs}; }
path(){
    # Parse and print $PATH
    clear;echo;echo '  $PATH (parsed)';echo
    declare IFS=:
    printf '  %s\n' $PATH
}
[[ $(type -t pushd) ]] && {
    push() {
        [[ "$@" ]] || { echo "===  REQUIREs 1 argument : folder path (abs|rel)"; return 99; }
        [[ -d "$*" ]] && { pushd "$*" > /dev/null 2>&1;return; }
        echo "=== Folder '$*' NOT EXIST"
    }
    pop() { popd > /dev/null 2>&1 ; }
    up(){ push "$(cd ..;pwd)" ; }
    root(){ push / ; }
    home(){ push "$HOME"; }
    temp(){ push "${TMPDIR:-/tmp}"; }
    DEV=/s/DEV
    [[ -d $DEV ]] || unset DEV
    [[ -d $DEV ]] && meta(){ push "$DEV/devops/meta"; }
    [[ -d $DEV ]] && infra(){ push "$DEV/devops/infra"; }
}
mode(){
    # octal human fname
    # ARGs: [path(Default:.)]
    [[ -f "$@" ]] && {
        find "${@%/*}" -maxdepth 1 -type f -iname "${@##*/}" -execdir stat --format="  %04a  %A  %n" {} \+ |sed 's,./,,'
        return 0
    }
    [[ -d "$@" ]] && d="$@" || d='.'
    find "$d" -maxdepth 1 -type d -execdir stat --format="  %04a  %A  %n" {} \+ |sed 's,./,,'
    echo ''
    find "$d" -maxdepth 1 -type f -execdir stat --format="  %04a  %A  %n" {} \+ |sed 's,./,,'
}
alias perms=mode # Depricated
owner(){
    # owner[uid] group[gid] perms[octal] fname
    # ARGs: [path(Default:.)]
    [[ -f "$@" ]] && {
        find "${@%/*}" -maxdepth 1 -type f -iname "${@##*/}" -execdir stat --format="  %U(%u)  %G(%g)  %A(%04a)  %n" {} \+ |sed 's,./,,'
        return 0
    }
    [[ -d "$@" ]] && d="$@" || d='.'
    find "$d" -maxdepth 1 -type d -execdir stat --format="  %U(%u)  %G(%g)  %A(%04a)  %n" {} \+ |sed 's,./,,'
    echo ''
    find "$d" -maxdepth 1 -type f -execdir stat --format="  %U(%u)  %G(%g)  %A(%04a)  %n" {} \+ |sed 's,./,,'
}
selinux(){
    # SELinux security context : See: man stat (%C)
    # ARGs: [path(Default:.)]
    [[ $(type -t getenforce) ]] || {
        echo "  REQUIREs: SELinux"
        return 0
    }
    [[ -f "$@" ]] && {
        find "${@%/*}" -maxdepth 1 -type f -iname "${@##*/}" -execdir stat --format=" %04a  %A  %C  %n" {} \+ |sed 's,./,,'
        return 0
    }
    [[ -d "$@" ]] && d="$@" || d='.'
    find "$d" -maxdepth 1 -type d -execdir stat --format=" %04a  %A  %C  %n" {} \+ |sed 's,./,,'
    echo ''
    find "$d" -maxdepth 1 -type f -execdir stat --format=" %04a  %A  %C  %n" {} \+ |sed 's,./,,'
}
#newest(){ find ${1:-.} -type f ! -path '*/.git/*' -printf '%T+ %P\n' |sort -r |head -n 1 |cut -d' ' -f2-; }
# newest(){
#     #TZ=Zulu
#     [[ -r $1 ]] && _dir="$@" || _dir=.
#     found="$(find "$_dir" -type f ! -path '*/.git/*' -printf '%T+ %P @ %TY-%Tm-%TdT%TH:%TMZ\n' |sort -r |head -n 1)"
#     [[ ${1,,} == 't' ]] &&
#         echo "$found" |cut -d' ' -f2- ||
#             echo "$found" |cut -d' ' -f2
# }

#########
# systemd
unitfiles(){ systemctl list-unit-files; }
journal(){ 
    [[ $1 ]] && { sudo journalctl --no-pager --full -e -u "$@"; return $?; }
    sudo journalctl --no-pager -e --since='1 hour ago'
}
status(){
    [[ $1 ]] || { type $FUNCNAME; return 1; }
    systemctl status --no-pager --full $1
}

#######
# Other

cpuinfo(){ 
    echo -e "arch\t\t: $(echo $HOSTTYPE |cut -d'"' -f2)"
    cat /proc/cpuinfo |grep -e name -e MHz -e cores -e siblings |sed 's/siblings/threads   /' |sort -u
}
alias cpu=cpuinfo

# Cgroup driver
cgroup(){
    fs=$(stat -fc %T /sys/fs/cgroup/)
    [[ $fs == 'tmpfs' ]] && printf v1 && return
    [[ $fs == 'cgroup2fs' ]] && printf v2 && return
    echo unknown
}

# Process
psp(){ # ps : Process info of declared pattern (command, PID, ...), else all of current user
    ps -axo user,pid,rss,pmem,pcpu,command \
      |grep -v grep \
      |grep -v 'ps -' \
      |grep -e PID -e "${@:-$USER}"
}

# Memory
rss(){ # Show actual (physical) memory usage (RSS, HWM, etc.) of a process by its command ($1)
    [[ $1 ]] || { type $FUNCNAME; return 1; }
    pid_of_cmd(){
        ps -C $1 |grep $1 |awk '{print $1}'
    }
    pid=$(pid_of_cmd $1) && cat /proc/$pid/status \
        |grep Vm |awk '{ printf "%-8s %5.0f %4s\n", $1, $2/1024,"MiB" }' |grep -v ' 0 '
}
meminfo(){
    cat /proc/meminfo |awk '{ printf "%-16s %10.0f %4s\n", $1, $2/1024,"MiB" }' |grep -v ' 0' 
}
alias mem=meminfo

# Current USER:GROUP
ug(){ printf "$(id -u):$(id -g)"; }

# Find all files hereunder containing pattern ($1)
grepall(){ [[ "$1" ]] && find . -type f -exec grep -il "$1" "{}" \+ ; }

# Crypto
AGE_ID="$HOME/.age/age-id-20250308"
AGE_ACCT=sempernow
agere(){
    type -t age-keygen >/dev/null 2>&1 &&
        type -t curl >/dev/null 2>&1 ||
            return 1

    curl -qsLf https://github.com/${AGE_ACCT}.keys
    curl -qsLf https://gitlab.com/${AGE_ACCT}.keys
    age-keygen -y "$AGE_ID" 2>/dev/null
}
ageen(){
    [[ -r "$@" ]] &&
        cat <(agere) |age -e -a -R - -o "${@}.age" "$@" ||
            type $FUNCNAME
}
agede(){
    [[ -r "$@" ]] || {
        type $FUNCNAME
        
        return 1
    }
    age -d -i ~/.ssh/gitlab_${AGE_ACCT} "$@" 2>/dev/null ||
        age -d -i ~/.ssh/github_${AGE_ACCT} "$@" 2>/dev/null ||
            age -d -i "$AGE_ID" "$@" 2>/dev/null ||
                echo "❌  ERR : Not decrypted"
}
randa(){
    # ARGs: [LENGTH(Default:32]
    cat /dev/urandom |tr -dc 'a-zA-Z0-9' |fold -w ${1:-32} |head -n 1
}
md5()    {( algo=$FUNCNAME ; _hash "$@" ; )}
sha()    {( algo=$FUNCNAME ; _hash "$@" ; )}
sha1()   {( algo=$FUNCNAME ; _hash "$@" ; )}
sha256() {( algo=$FUNCNAME ; _hash "$@" ; )}
sha512() {( algo=$FUNCNAME ; _hash "$@" ; )}
rmd160() {( algo=$FUNCNAME ; _hash "$@" ; )}
_hash() {
    # ARGs: PATH|STR
    print_hash(){
        #REQUIREs putclip
        printf "%s" "${@:(-1)}" # print last positional-param only
    #     [[ "$_HASH_QUIET" ]] || {
    #         [[ $(type -f putclip) ]] && putclip "${@:(-1)}" # to clipboard unless '-q'
    #     }
    }
    # quiet mode on '-q' (prepended to input)
    [[ "${1,,}" == '-q' ]] && { _HASH_QUIET=1 ; shift ; } || unset _HASH_QUIET

    if [[ "$@" && "$algo" ]]
    then
        if [[ -f "$@" ]]
        then
            # -- file --
            [[ "$_HASH_QUIET" ]] || echo $algo "[FILE] '${@##*/}' ..."
            print_hash $( openssl $algo "$*" )
        else
            # -- string --
            [[ "$_HASH_QUIET" ]] || {
                echo $algo "[STR] '$@' ..." >&2
            }
            print_hash $( echo -n "$*" |openssl $algo )
        fi
    else
        REQUIREs errMSG
        [[ ! "$@"    ]] && errMSG "$FUNCNAME FAIL @ null input"
        [[ ! "$algo" ]] && errMSG "$FUNCNAME FAIL @ null 'algo'"
    fi
}
woff2base64() { [[ "$(type -t base64)" && -f "$@" ]] && base64 -w 0 "$@"; }

#########
# Network

fws(){ # info of all services of zone $1 else 1st-found active zone else public zone
    zone=$1 || zone=$(sudo firewall-cmd --get-active-zone |head -n1) || zone=public
    printf "%s\n" $(sudo firewall-cmd --list-services --zone=$zone) |
        xargs -I{} sudo firewall-cmd --info-service={}
}

dns2ip(){
    printf "%s" "$(nslookup $1 |grep -A1 Name |tail -n1 |cut -d' ' -f2)"
}

cidr(){
    ip --color=never -4 -brief addr "$@" |
        command grep -v -e lo -e docker |
        command grep UP |
        head -n1 |
        awk '{print $3}'
}
cidr4(){ cidr "$@"; }
cidr6(){
    ip --color=never -6 -brief addr "$@" |
        command grep -v -e lo -e docker |
        command grep UP |
        head -n1 |
        awk '{print $3}'
}
ip4(){ cidr4 |cut -d'/' -f1; }
ip6(){ cidr6 |cut -d'/' -f1; }
link(){ ip --color=never -brief link |grep -v -e lo -e docker |grep UP |cut -d' ' -f1; }
scan(){
    case $1 in 
        "subnet"|"cidr") # Scan subnet (CIDR) for IP addresses in use.
            [[ $2 ]] && cidr="$2" || cidr="$(cidr)"
            [[ $cidr ]] || {
                [[ $(type -t errMSG) ]] && errMSG '  CIDR not found.'
                return 1
            }
            echo "=== Hosts in subnet $cidr"
            REQUIREs arp-scan && sudo arp-scan $cidr \
            || REQUIREs nmap && nmap -sn $cidr

            return $?
        ;;
        "ports"|"ip") # Scan IP address for ports in use.
            [[ $2 ]] && ip="$2" || ip="$(cidr |cut -d/ -f1)"
            [[ $ip ]] || {
                REQUIREs errMSG && errMSG '  IP address not found.'
                return 1
            }
            echo "=== Ports in use at $ip"
            REQUIREs nc || return
            seq ${3:-1} ${4:-1024} \
                |xargs -IX nc -zvw 1 $ip X 2>&1 >/dev/null \
                |grep -iv fail |grep -iv refused
        ;;
        *)
            echo "  USAGE: 
              $FUNCNAME subnet|cidr [CIDR($(cidr))]
              $FUNCNAME ports|ip [IP_ADDR($(ip4))] [minPORT(1) [maxPORT(1024)]]
            "
            return 1
        ;;
    esac
}

tls(){
    REQUIREs openssl || return 
    unset artifact
    case $1 in
        "cnf")
            # Make configuration file (.cnf) for CSR of an End-entity (Server)
            [[ $2 ]] || {
                echo "  USAGE: $FUNCNAME cnf CN"
                # ***  PRESERVE TABS of HEREDOC  ***
				cat <<-EOH
			
				  Set environment variable(s) to override their default:
			
				  TLS_O='Riddler 8132'
				  TLS_OU=Ops
				  TLS_L=Gotham
				  TLS_ST=NY
				  TLS_C=US
				EOH

                return 0
            }
            artifact="${2}.cnf"
            # ***  PRESERVE TABS of HEREDOC  ***
			cat <<-EOH |tee $artifact
			[ req ]
			prompt              = no
			default_bits        = 2048
			default_md          = sha256
			distinguished_name  = req_distinguished_name 
			req_extensions      = req_ext
			[ req_distinguished_name ]
			CN              = $2
			O               = ${TLS_O:-Penguin Inc}
			OU              = ${TLS_OU:-DevOps}
			L               = ${TLS_L:-Gotham}
			ST              = ${TLS_ST:-NY}
			C               = ${TLS_C:-US}
			[ req_ext ]
			subjectAltName          = @alt_names
			keyUsage                = critical, digitalSignature, keyEncipherment
			extendedKeyUsage        = serverAuth
			subjectKeyIdentifier    = hash
			authorityKeyIdentifier  = keyid:always,issuer
			[ alt_names ]
			DNS.1 = $2
			DNS.2 = *.$2
			EOH
        ;;
        "key")
            ### Generate RSA private key
            [[ $2 ]] || {
                echo "  USAGE: $FUNCNAME key CN [key-length(Default:2048)]"
                return 0
            }
            artifact=${2}.key
            openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:${3:-2048} -out $artifact
        ;;
        "csr")
            [[ $2 == "make" ]] && {
                    [[ $3 && -f $4 && -f $5 ]] && {
                        # Make CSR
                        artifact=$3.csr
                        openssl req -new -sha256 -key $5 -extensions req_ext -config $4 -out $artifact
                    } || {
                        [[ $3 && -f $4 ]] && {
                            # Make Private Key and CSR
                            artifact=$3.csr
                            openssl req -new -newkey rsa:${5:-2048} -extensions req_ext -config $4 -noenc -keyout $3.key -out $3.csr
                        } || {
                            echo '  USAGE:'
							cat <<-EOH
							    Make CSR using existing private key:
							    $FUNCNAME csr make CN CNF_PATH PRIVATE_KEY_PATH [Key-length(Default:2048)]

						    Make CSR and private key:
						    $FUNCNAME csr make CN CNF_PATH [Key-length(Default:2048)]
							EOH
                            return 0
                        }
                    }
                } || {
                    # Verify CSR
                    artifact="/tmp/tls.verify.${2##*/}.log"
                    [[ -f $2 ]] || {
                        echo "  USAGE: $FUNCNAME csr CSR_PATH"
                        return 0
                    }
                    openssl req -text -noout -verify -in $2 
                }
            ;;
        "server")
            # GET full-chain (-showcerts) certificate of host (server) $2 via port $3
            [[ $2 ]] || {
                echo "  USAGE: $FUNCNAME server HOST [PORT(Default:443)]"
                return 0
            }
            artifact="/tmp/tls.server.${2}_${3:-443}_full_chain_cert.log"
            # -servername limits to the declared domain name using Server Name Indication (SNI)
            openssl s_client -connect $2:${3:-443} -servername $2 -showcerts < /dev/null 
        ;;
        "crt")
            [[ $2 == "verify" ]] && {
                # Verify the server's ca-signed certificate against the CA that signed it.
                [[ -f $3 && -f $4 ]] && {
                    artifact=/tmp/tls.crt.verify.${3##*/}.log
                    openssl verify -CAfile $3 $4 
                } || {
                    # CA_CERT_BUNDLE is path to trust-store file; concatenated CA certificates in PEM format.
                    # SERVER_CERT is path to server's full-chain certificate AKA certificate-chain file
                    echo "  USAGE: $FUNCNAME crt verify CA_CERT_BUNDLE SERVER_CERT"
                    return 0
                }
            }
            [[ $2 == "parse" ]] && {
                [[ -f $3 ]] && {
                    artifact=/tmp/tls.crt.parse.${3##*/}.log
                    x509v3='subjectAltName,issuerAltName,basicConstraints,keyUsage,extendedKeyUsage,authorityInfoAccess,subjectKeyIdentifier,authorityKeyIdentifier,crlDistributionPoints,issuingDistributionPoints,policyConstraints,nameConstraints'
                    openssl x509 -in $3 -noout -subject -issuer -startdate -enddate -serial -ext "$x509v3"
                } || {
                    echo "  USAGE: $FUNCNAME crt parse SERVER_CERT"
                    return 0
                }
            }
        ;;
        *)

            echo '  USAGE: '
            # ***  PRESERVE TABS of HEREDOC  ***
			cat <<-EOH
			    tls key         : Make RSA private key file (.key)
			    tls cnf         : Make configuration file (.cnf) for CSR
			    tls csr make    : Make CSR file (.csr)
			    tls csr         : Verify CSR
			    tls crt parse   : Parse certificate
			    tls crt verify  : Verify certificate
			    tls server      : Get full-chain certificate of a server
			EOH
        ;;
    esac
    [[ -f $artifact ]] && printf "\n  %s\n" "See: $artifact"
}

#####
# ssh

unalias fpr 2>/dev/null
fpr(){ ssh-keygen -E sha256 -lf "$@"; }
unalias fprs 2>/dev/null
fprs(){ ssh-keygen -lf "$@"; }
hostfprs(){
    # Scan host and show fingerprints of its keys to mitigate MITM attacks.
    # Use against host's claimed fingerprint on ssh-copy-id or other 1st connect.
    [[ "$1" ]] && {
        ssh-keyscan $1 2>/dev/null |ssh-keygen -lf -
    } || {
        printf "\n%s\n" 'Usage:'
        echo "$FUNCNAME \$host (FQDN or IP address)"
    }
    printf "\n%s\n" 'Push key to host:'
    echo 'ssh-copy-id -i $keypath $ssh_user@$host'
}

######
# Meta

declared(){
    [[ $1 == 'v' ]] && vars
    [[ $1 == 'f' ]] && fx
    [[ $1 ]] || printf "  %s\n\n  %s\n" 'List all user-defined variables (v), or functions (f).' 'USAGE: declared v|f'
}
fx(){ declare -f; }
vars(){ declare -p |command grep -E 'declare -(x|[a-z]*x)' |cut -d' ' -f3- |command grep -v __git; }
envsans(){
    # Print environment variables without functions
    declare -p |grep -E '^declare -x [^=]+=' |sed 's,",,g' |awk '{print $3}'
    printf "\n\t(%s)\n" 'Environment variables containing special characters may not have printed accurately.'
}

colors() {
    # Each is a background color and contrasting text color.
    # Usage: colors;printf "\n %s\n" "$green MESSAGE $norm"
    [[ "$TERM" ]] || return 99
    normal="$( tput sgr0 )"                       # reset
    red="$(    tput setab 1 ; tput setaf 7 )"
    yellow="$( tput setab 3 ; tput setaf 0 )"   # blk foreground
    green="$(  tput setab 2 ; tput setaf 0 )"   # blk foreground
    greenw="$( tput setab 2 ; tput setaf 7 )"   # wht foreground
    blue="$(   tput setab 4 ; tput setaf 7 )"
    gray="$(   tput setab 7 ; tput setaf 0 )" ; alias grey=gray
    aqua="$(   tput setab 6 ; tput setaf 7 )"
    aqux="$(   tput setab 6 ; tput setaf 6 )"   # hidden text
    zzz="$normal"
    norm="$normal"
}

errMSG() {
    # ARGs: MESSAGE
    [[ "$TERM" ]] &&
        colors;printf "\n $red ERROR $norm : %s\n" "$@" ||
            printf "\n %s\n" " ERROR : $@"
    return 99
}

REQUIREs(){
    # ARGs: FUNCNAME1 [FUNCNAME2 ...]
    # function[s] exist test; exit on fail; $? is 86 on fail, else 0
    declare list
    for func in "$@"
    do  # exist-test ; append list on fail
        [[ "$( type -t $func )" ]] || list="${list}'${func}', "
    done
    [[ "$list" ]] && { # inform of calling-function and non-existent functions
        list="${list%,*}" ; errMSG "'${FUNCNAME[1]}' REQUIREs function[s] that do NOT EXIST ..."
        printf '\n %s\n' "$list"
        # return|exit [86] on fail per @ 1x-bash or not
        #[[ $PPID -eq $_PID_1xSHELL ]] && return 86 || exit 86 # failing
        return 86
    }
    return 0
}
putclip() {
    # ARGs: STR
    # $@ => clipboard [erases it on null input]
    if [[ ! "$_CLIPBOARD" ]] # set clipboard per OS, once per Env.
    then
        # Win7: clip; Linux: xclip -selection c; OSX: pbcopy; Cygwin: /dev/clipboard
        for i in clip xclip pbcopy
        do
            [[ "$( type -t $i )" ]] && _CLIPBOARD="$i"
        done
        [[ "$OSTYPE" == 'cygwin' ]]    && _CLIPBOARD='/dev/clipboard'
        [[ "$OSTYPE" == 'msys' ]]      && _CLIPBOARD='/dev/clipboard'
        [[ "$_CLIPBOARD" == 'xclip' ]] && _CLIPBOARD='xclip -i -f -silent -selection clipboard'
        # '-i -f -silent' and null redirect is workaround for command-sustitution case ['-loop #' bug]
    fi
    # validate clipboard; rpt & exit on fail
    [[ "$_CLIPBOARD" ]] || { errMSG "$FUNCNAME[clipboard-not-exist]"; return 86; }
    # put :: $@ => clipboard
    [[ "$@" ]] && {
        [[ "$OSTYPE" == 'linux-gnu' ]] && { printf "$*" | $_CLIPBOARD > /dev/null; true; } || { printf "$*" > $_CLIPBOARD; true; }
    } || {
        [[ "$OSTYPE" == 'linux-gnu' ]] && { : | $_CLIPBOARD > /dev/null; true; } || { : > $_CLIPBOARD; }
    }
}
x(){
    # Exit shell; show post-exist shell lvl;
    # clear user history if @ 1st shell
    clear #; shlvl
    [[ "$BASHPID" == "$_PID_1xSHELL" ]] && {
        history -c; echo > "$_HOME/.bash_history" # clear history
        github ssh kill # kill all ssh-agent processes
    }
    exit > /dev/null 2>&1
}
shlvl(){
    # ARGs: [{msg}]
    # Show shell level [and message]
    colors; [[ "$@" ]] && _msg=": $@" || unset _msg
    [[ "${FUNCNAME[1]}" == 'x' ]] && _shlvl=$(( $SHLVL - 1 )) || _shlvl=$SHLVL
    [[ "$_shlvl" == "1" ]] && [[ "$PPID" == "$_PID_1xSHELL" ]] && { printf "\n %s\n" "$red $(( $_shlvl ))x ${SHELL##*/} $norm $_msg"; } || { printf "\n %s\n" "$(( $_shlvl ))x ${SHELL##*/} $_msg"; }
}

## End here if not interactive
# [[ "$-" != *i* ]] && return
[[ -z "$PS1" ]] && return 0

[[ "$BASH_SOURCE" ]] && echo "@ $BASH_SOURCE"

