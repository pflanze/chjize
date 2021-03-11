
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


root_add_ssh_keys_from_file () {
    local from
    from=$1

    local to
    to=$(uid_authorizedkeysfile 0)

    if [ "$from" = "$to" ]; then
        echo "$0: odd, should not be identical, BUG?: '$from', '$to'"
        # Well, unless both users were really configured to have
        # the same dir, but that would be odd since
        # insecure/voiding sudo anyway.
        #do_nosudo_force # really?
        false
    else
        local cleaned
        cleaned=$(mktemp)

        if [ -e "$to" ]; then
            # Remove entries from AWS
            01ok grep -v 'Please login as the user' < "$to" > "$cleaned"
            # keep backup, all of them due to concurrency, use file's inode
            # number for guaranteed conflict freedom
            local ino
            ino=$(stat --printf '%i' "$to")
            ln "$to" "$to.$ino~" || true
        fi

        # Add entries from $from which are not in $cleaned
        local tmp
        tmp=$(mktemp)
        {
            cat "$from"
            echo
            cat "$cleaned"
            echo
        } > "$tmp"
        local tmp2
        tmp2=$(mktemp)
        LANG=C sort -u < "$tmp" > "$tmp2"
        local new
        new=$(mktemp -p "$(dirname "$to")")
        egrep -v '^$' < "$tmp2" > "$new"
        # new is private, make it "normal"
        chmod a+r "$new"
        mv -f "$new" "$to"
    fi
}

