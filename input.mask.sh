#!/usr/bin/env bash
shopt -s extglob 
trim(){ local x="${@##+([[:space:]])}"; x="${x%%+([[:space:]])}"; printf "%s" "$x"; }
export -f trim

printf "%s: " "Password" >/dev/tty

exit

PW=''
while IFS= read -rsn1 ch; do
    # Enter: empty (delimiter), \n (Linux), or \r (macOS/WSL)
    if [[ -z $ch || $ch == $'\n' || $ch == $'\r' ]]; then
        printf '\n'
        break
    fi
    # Backspace/Delete
    if [[ $ch == $'\177' || $ch == $'\b' ]]; then
        if ((${#PW})); then
            PW=${PW%?}
            printf '\b \b'
        fi
    else
        PW+=$ch
        printf '\U25cf'
    fi
done
export PASS="$(printf "%s" "$(trim "$PW")" |base64)"

