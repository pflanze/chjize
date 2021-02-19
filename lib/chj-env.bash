
function xcheck_location {
    local expected="$1"

    local OS=$(uname -o)

    if [ "$OS" = Cygwin ]; then
        # 'C:\cygwin64\opt\chj\chjize\bin\chjize' instead of
        # '/opt/chj/chjize/sbin/action', I don't care, just ignore the
        # check
        true
    else
        if [ "$(readlink -f "$0")" != "$(readlink -f "$expected")" ]
        then
            echo "wrong location: place this repository at /opt/chj/chjize/"
            exit 1
        fi
    fi
}

PATH=/opt/chj/chjize/bin:/opt/chj/chjize/sbin:/opt/chj/git-sign/bin:"$PATH"
export VERIFY_SIG_ACCEPT_KEYS="A54A 1D7C A1F9 4C86 6AC8  1A1F 0FA5 B211 04ED B072"

