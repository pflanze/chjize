if [ -d /opt/chj/bin ] ; then
    PATH=/opt/chj/bin:"${PATH}"
fi

if [ -d /opt/functional-perl/bin ] ; then
    PATH=/opt/functional-perl/bin:"${PATH}"
fi

if [ -d ~/bin ] ; then
    PATH=~/bin:"${PATH}"
fi

if [ -d ~/local/bin ] ; then
    PATH=~/local/bin:"${PATH}"
fi

ulimit -S -v 3000000
export EDITOR=emacs
unset LESSOPEN
unset LESSCLOSE

# export LANG=de_CH.UTF8
