# What?

Mod a fresh Amazon Ubuntu server installation to have the [functional
perl](http://functional-perl.org/) project libraries with all
interesting dependencies installed, in addition to my own preferred
utilities so that I'm feeling comfortable in the shell.

(This was originally written to support a functional-perl live
workshop.)

# How?

    ssh ubuntu@$YOUR_SERVER_IP
    sudo su -
    apt-get install -y git
    cd /opt/
    git clone https://github.com/pflanze/fperl-demo-install.git
    cd fperl-demo-install/
    ./install

(The install step requires you to enter `yes` a couple times.)
