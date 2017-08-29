# Chjize

Mod a bare-bones (e.g. debootstrap) Debian install into one that I
like.

## How?

    sudo su -
    apt-get install -y git
    cd /opt/
    git clone https://github.com/pflanze/chjize.git
    cd chjize/
    ./chjize-main

## Optional: functional perl

Mod a fresh Amazon Ubuntu server installation to have the [functional
perl](http://functional-perl.org/) project libraries with all
interesting dependencies installed, in addition to my own preferred
utilities so that I'm feeling comfortable in the shell.

(This was originally written to support a functional-perl live
workshop.)

    ./chjize-fperl

(The install step requires you to enter `yes` a couple times.)
