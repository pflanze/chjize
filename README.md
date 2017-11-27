# Chjize

Mod a bare-bones (e.g. debootstrap) Debian install into one that I
like.


## How?

    sudo su -
    apt-get install -y git make
    cd /opt/
    mkdir chj
    cd chj
    git clone https://github.com/pflanze/chjize.git
    cd chjize/
    
You can verify signed git tags that you've got the pristine source (note that `cj-key.asc` is included in this repo and the `chj` rule imports it to gpg, which means that if you got a trusted checkout of this repository then this can be skipped and it will still have the key and properly check signatures of other repositories it fetches):

    gpg --recv-key A54A1D7CA1F94C866AC81A1F0FA5B21104EDB072
    version=v`git tag -l | grep ^v | sed s/^v// | LANG=C sort -rn | head -1`
    git checkout "$version"
    git tag -v "$version"
    # Check that the above command says "Good signature", and shows
    #   my fingerprint (same as above, feel free to google it, too)
    #   if you don't have a trust path to the key.
    # You can also do the more paranoid verification of running the
    #   script lines shown by the above command (those lines starting 
    #   with a "$"), and verifying that you get the same output as shown.

Once you trust that the source is mine:
    
    make help
    make chj # etc.


## Optional: functional perl

Mod a fresh Amazon Ubuntu server installation to have the [functional
perl](http://functional-perl.org/) project libraries with all
interesting dependencies installed, in addition to my own preferred
utilities so that I'm feeling comfortable in the shell.

(This was originally written to support a functional-perl live
workshop.)

    make fperl

(The install step requires you to enter `yes` a couple times.)
