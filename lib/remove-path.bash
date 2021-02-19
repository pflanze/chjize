
# Delete a path from PATH
remove-path() {
    local path=$1
    export path
    PATH=$(printf '%s' "$PATH" | perl -wne 'while (s{(^|:)\Q$ENV{path}\E/?(:|\z)}{ length($1) ? (length($2) ? $1 : "") : ""}e) {}; print or die $!')
}

