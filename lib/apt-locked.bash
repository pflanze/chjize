
# Get our own lock so that we can use make -j2 without Debian erroring
# out on us (sigh).

source /opt/chj/chjize/lib/remove-path.bash

is_update () {
    # true if any of the arguments are looking like it's doing an
    # installation operation
    local arg
    for arg in "$@"; do
        case "$arg" in
            update | upgrade | dist-upgrade | dselect-upgrade \
                | install | download | source)
                return 0;;
            *)
            ;;
        esac
    done
    return 1
}

conditional_apt_update () {
    if is_update "$@"; then
        # (XX could optimize this by defining this in a library
        # instead of as a separate process: )
        perhaps-aptupdate
    fi
}

apt-locked() {
    local PATH=$PATH
    remove-path /opt/chj/chjize/sbin
    mkdir -p /root/tmp/
    flock /root/tmp/.apt.lock "$@"
}
