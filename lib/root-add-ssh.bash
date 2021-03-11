
set -euo pipefail
IFS=


01ok () {
    set +e
    "$@"
    [ $? -eq 0 -o $? -eq 1 ]
}

passwd_field () {
    local passwd=$1
    local fieldindex=$2
    local - ; set +x
    set -eu
    local IFS
    IFS=:
    read -ra pw < <(printf '%s\n' "$passwd")
    printf '%q\n' "${pw[$fieldindex]}"
}

uid_passwd () {
    local uid=$1
    local - ; set +x
    set -eu
    getent passwd "$uid"
}

uid_name () { local uid=$1; local - ; set +x; set -eu; local passwd; passwd=$(uid_passwd "$uid"); passwd_field "$passwd" 0; }
uid_home () { local uid=$1; local - ; set +x; set -eu; local passwd; passwd=$(uid_passwd "$uid"); passwd_field "$passwd" 5; }

uid_authorizedkeysfile () {
    local uid=$1
    local - ; set +x
    set -eu
    local home
    home=$(uid_home "$uid")
    printf '%q\n' "$home/.ssh/authorized_keys"
}


