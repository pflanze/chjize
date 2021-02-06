# Chjize

Mod a bare-bones (e.g. debootstrap) Debian install into one that I
like. Also partially works on Cygwin (at least the chj-perllib target
does).


## How?

    sudo su -
    apt-get update
    apt-get install -y git make gnupg
    cd /opt/
    mkdir chj
    cd chj
    git clone https://github.com/pflanze/chjize.git
    cd chjize/
    
You can verify via signed git tags that you've got the pristine source
(note that most rules import the key to gpg, too, and as the key is
included in the repository, this means that if you got a trusted
checkout of this repository then this verification step can be
skipped; it will properly check signatures of other repositories it
fetches in any case):

    gpg --import cj-key.asc
    version=r`git tag -l | grep ^r | sed s/^r// | LANG=C sort -rn | head -1`
    git checkout "$version"
    git tag -v "$version"
    # Check that the above command says "Good signature", and shows
    #   my fingerprint (A54A1D7CA1F94C866AC81A1F0FA5B21104EDB072, feel 
    #   free to google it) if you don't have a trust path to the key.
    # You can also do the more paranoid verification of running the
    #   script lines shown by the above command (those lines starting 
    #   with a "$"), and verifying that you get the same output as shown.

Once you trust that the source is mine, run:
    
    make help

for the list of available targets. To e.g. only install my software
into `/opt/chj` (and dependences, which is debianpackages in this
case, see `Makefile` for details), run:

    make chj

