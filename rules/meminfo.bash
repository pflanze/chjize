
meminfo_get () {
    export FIELD=$1
    export UNIT=$2
    set -eu
    local meminfo
    meminfo=$(cat /proc/meminfo)
    echo "$meminfo" | perl -wne \
      '/^\Q$ENV{FIELD}\E:\s*(\d+)\s*$ENV{UNIT}/ and push @vs, $1; 
       END { @vs == 1 or die "found ".@vs." values not 1"; print @vs, "\n" or die }'
}

