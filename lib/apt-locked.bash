
# Get our own lock so that we can use make -j2 without Debian erroring
# out on us (sigh).

source /opt/chj/chjize/lib/remove-path.bash

is_update () {
    # true if any of the arguments are looking like it's doing an
    # installation operation
    local arg
    for arg in "$@"; do
        case "$arg" in
            # no need to include 'update' here as then it will do it
            # anyway; XX although, update will be run on the next
            # update-"requiring" apt command anyway.
            upgrade | dist-upgrade | dselect-upgrade \
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
        if [ "${CONDITIONAL_APT_UPDATE-0}" = 0 ]; then
            # (XX could optimize this by defining this in a library
            # instead of as a separate process: )
            CONDITIONAL_APT_UPDATE=1 perhaps-aptupdate
        fi
    fi
}

apt-locked() {
    local PATH=$PATH
    remove-path /opt/chj/chjize/sbin
    mkdir -p /root/tmp/
    # HACK: why do we get exit code 150 sometimes?
    flock /root/tmp/.apt.lock "$@" || true
}
