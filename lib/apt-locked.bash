
# Get our own lock so that we can use make -j2 without Debian erroring
# out on us (sigh).

source /opt/chj/chjize/lib/remove-path.bash

apt-locked() {
    remove-path /opt/chj/chjize/sbin
    mkdir -p /root/tmp/
    flock /root/tmp/.apt.lock "$@"
}
