# Chjize

This changes a pristine Debian (or possibly Ubuntu or Cygwin (at least
the chj-perllib target works)) install in ways that I like, including
software installs and configuration modifications.

Currently uses cryptographic signatures without exception to ensure
code integrity.

## How to use

Note: you can get a script [here](install-chjize) that runs the same as the
following. How it is meant to be used is, you check out chjize on your
developer machine, and then when you want to install chjize on another
machine you copy over the script and then run it instead of copying
these instructions.

As root:

    apt-get update
    apt-get install -y git make gnupg
    mkdir -p /opt/chj
    cd /opt/chj
    git clone https://github.com/pflanze/chjize.git
    cd chjize/
    
You can verify via signed git tags that you've got the pristine source
(note that most rules import the key to gpg, too, and as the key is
included in the repository, this means that if you got a trusted
checkout of this repository then this verification step can be
skipped; it will properly check signatures of other repositories it
fetches in any case):

    gpg --import cj-key.asc
    gpg --import cj-key-2.asc
    version=r$(git tag -l | grep ^r | sed s/^r// | LANG=C sort -rn | head -1)
    git checkout -b local "$version"
    tmpout=$(mktemp)
    tmperr=$(mktemp)
    git tag -v "$version" > "$tmpout" 2> "$tmperr" || { cat "$tmpout" "$tmperr"; false; }
    cat "$tmpout" "$tmperr"
    # Check that the above command gives "Good signature", and (if warning) shows
    #   my fingerprint 7312F47D9436FBF8C3F80CF2748247966F366AE9 if you don't have
    #   a trust path to the key (which is signed by my older key A54A1D7CA1F94C866AC81A1F0FA5B21104EDB072 
    #   (A54A 1D7C A1F9 4C86 6AC8.*1A1F 0FA5 B211 04ED B072), which you can google) 
    if grep -q WARNING "$tmperr"; then grep "7312 F47D 9436 FBF8 C3F8  0CF2 7482 4796 6F36 6AE9" "$tmperr"; fi
    
    # You can also do the more paranoid verification of running the
    #   script lines shown in the tag (the lines starting with a `$`),
    #   and verifying that you get the same output as shown:
    sumsSig=$(perl -we 'local $/; $a=<STDIN>; $a=~ s{.*\n\$[^\n]*sha256sum\n}{}s; print $a' < "$tmpout")
    sumsLocal=$(git ls-files -z | xargs -0 --no-run-if-empty -s 129023 -n 129023 sha256sum)
    if ! diff <(echo "$sumsSig") <(echo "$sumsLocal"); then echo "check failure"; false; fi

Once you trust that the source is mine, run:
    
    PATH=/opt/chj/chjize/bin:$PATH
    chjize -h

for the list of available targets (the same as shown
[below](#current-list-of-targets)). To e.g. only install my software
into `/opt/chj` (and dependences, see `targets.mk` or the
[graph](#graph-of-target-dependencies) below), run:

    chjize chj

Unlike Ansible, this caches which actions were already done, and is
thus more efficient when asking the same target repeatedly (even
across runs). If an action for some reason really should be re-run,
unlink the file with the same name as the target.

The `moduser` target, or `mod-user` script, sets up bash startup files
so that `PATH` is set so that `chjize` is found automatically.

Chjize may work with parallel builds (`chjize -j2` and higher
numbers), since we're now using wrappers around `apt-get` and `apt`
(in [bin/](bin/)) that use waiting locks.

## Client side automation

To set up servers, some more client side automation is desirable. For
an example (just a recipe) see
[client-side-todo](client-side-todo.md).

## Current list of targets

(Note: these are copied from [`targets.mk`](targets.mk) via `chjize README.md`.)

### release


### graph-deps

Install dependencies to run the `graph` target.

### key

Import cj-key.asc into the keyring of the current user.

### debian_upgrade

Upgrade the system (via dist-upgrade), necessary on a fresh instance
on typical cloud hostings like Amazon's.

### fonts

Install some fonts, amongst them Inconsolata for urxvt.

### urxvt

Install `rxvt-unicode` and trim it down for security and simplicity.

### debianpackages

Install my preferred Debian packages that are command-line only.

### debianpackages-x

Install my preferred Debian packages requiring X11.

### chj-perl-debian

Install the Perl packages from Debian needed for chj-bin.

### fperl-perl-debian

Install the Perl packages from Debian needed for fperl.

### imageprocessing

Install Debian packages around image processing (like optipng, gimp, mat2)

### cplusplus-compiler

Install `g++`.

### cplusplus

Packages for development in C++.

### git-sign

Check out [git-sign](https://github.com/pflanze/git-sign); used by
most other targets.

### chj-perllib-checkout


### chj-perllib

Install (via symlink)
[chj-perllib](https://github.com/pflanze/chj-perllib). These depend
on `fperl` now, thus that is installed as well.

### chj-bin-checkout


### chj-bin

Install [chj-bin](https://github.com/pflanze/chj-bin).

### debian-emacs

Install GNU Emacs via APT.

### emacs

Install debian-emacs. 

### chj-emacs

Checkout `chj-emacs`. Does not run `make` in it.

### emacs-full

Install emacs, including cloning `chj-emacs` in `/opt/chj` and
running `make` which installs further Debian packages (including
GHC, currently); you still also need to run `make` per user in
`.chj-emacs` after `mod-user` to get the local checkouts and
symlinks, though.

### wget

Install wget from Debian

### get_codium_deb


### vscodium

Install vscode from a binary off GitHub, WARNING: just hashed once
on first retrieval. HACK, unfinished: needs `slim-desktop` or
similar to be installed or add exact dependencies to the action, or
run apt-get -f install for fixing it up.

### fastrandom-checkout


### fastrandom

Install [fastrandom](https://github.com/pflanze/fastrandom).

### cj-git-patchtool

Install [cj-git-patchtool](https://github.com/pflanze/cj-git-patchtool).

### locales

Automatically configure some (English and German speaking) locales.

### debconf-noninteractive

Automatically configure debconf to be in Noninteractive mode (run
this to avoid other targets waiting for inputs; also, it will be the
only mode that works with -j2).

### chj

Check out the last tagged versions of various repositories into
`/opt/chj` (uses signed tags via git-sign to ensure you get what I
signed)

### chj-x

Chj including parts requiring X11

### dotconfig-xfce4-checkout

Check out [Xfce4 .config
files](https://github.com/pflanze/dotconfig-xfce4), which are used
by [chjize-xfce-setup](bin/chjize-xfce-setup).

### xfce-local

Xfce4 desktop, local. Comes with
`/opt/chj/chjize/bin/chjize-xfce-setup` to configure Xfce4 the way I
like (optionally run afterwards--see message emitted by this target
for some more detail). NOTE: better do not use this target directly,
but rather use `xfce4_load_profile` or one of the `..-desktop` ones.

### xfce-server

Same as xfce-local, but tries to avoid installing the xserver
packages.

### xfce4_load_profile


### load_profile

Set up Debian so that a graphical login will read the `~/.profile`
file (which they stopped doing at some point, dunno why); currently
only implemented for Xfce.

### moduser

Modify the `/root`, `/etc/skel`, and if present `/home/chris`
directories to use a checkout of
[chj-home](https://github.com/pflanze/chj-home); it should safely
store previous versions of your files in the Git repository that's
at this place before checking out my versions, see them via `gitk
--all`. This also sets up emacs to work nicely with Gambit, see
below. Note: if there is a `.git` directory in those directories
before, it will ask whether to continue by first moving those to
`/root/.trash/`.

If you want to modify a particular user's home without affecting the
other users, instead run `/opt/chj/chjize/bin/mod-user` as that user
(in its home dir)

### Module-Locate-checkout

`Module::Locate` has no signature on CPAN, thus I forked, verified
and signed it myself.

### Module-Locate


### Test-Pod-Snippets-checkout


### Test-Pod-Snippets

`Test::Pod::Snippets`, has a CPAN signature but for ease of checking
I forked, verified and signed it myself. Depends on
libpod-parser-perl from fperl-perl-debian.

### fperl-test

`fperl-noinstall` and the necessary dependencies to run its test
suite. Run the test suite.

### fperl-noinstall

Install the [Functional Perl](http://functional-perl.org) library
and its dependencies. Currently installs dependencies only from
Debian, and Functional Perl itself via Git and checks the signature,
thus is secure and won't ask questions (assuming
`debconf-noninteractive` was run).  Does not actually run `make
install`, thus Programs using functional-perl need to `use lib
/opt/functional-perl/lib;`! For a full installation, use the `fperl`
target.

### fperl

This is the `fperl-noinstall` target but also *does* run `make
install`. (This still does not access CPAN, and thus is still
secure.)

### gambit-checkout


### gambit

Install a patched version of the Gambit Scheme system.

### cj-qemucontrol-checkout


### cj-qemucontrol

Install [cj-qemucontrol](https://github.com/pflanze/cj-qemucontrol).

### dnsmasq

Install `dnsmasq` from Debian. (Used by `serve-dhcp` from
`chj-bin`.)

### qemu

Install Qemu, cj-qemucontrol, dnsmasq, and run
[qemu-adduser](bin/qemu-adduser) to create the user specified in
`$QEMU_USER` or the default `qemu` if not given, and give it the
necessary permissions.

### chroot-desktop

Desktop things still needed in a chroot (via `chrootlogin` tool from
chj-bin) running inside a deskop which is installed on the host.

### slim-desktop

Xfce4, desktop packages.

### real-desktop

`slim-desktop`, but also setup for real hardware desktops/laptops (not VPSs or VMs).

### perf

`linux-perf` and perhaps in the future other performance benchmarking tooling.

### full-desktop

`slim-desktop`, but also removes pulseaudio and installs jack, and
removes the login managers. Xfce4 has to be started via `startx`
from the console after this! (That latter part was a hack to work
around some issues in Debian stretch / get what I wanted.)

### full-desktop_autoremove

The `full-desktop` target but also runs `apt-get autoremove` to free
up the space taken by now unused packages.

### dnsresolver

Install and configure a local dns resolver (unbound).

### mercurial

Install mercurial, and hg-fast-export from either Debian or upstream
source.

### earlyoom

Install earlyoom (and, todo: configure it)

### security

Security relevant actions, like divert cupsd so it never runs by accident.

### system

Ensure basic system readyness for any system.

### fail2ban

fail2ban, with some config tweaks for stricter SSH blocking

### ssh-server

SSH service

### slim-vncserver

Server side VNC setup, to be used via client side VNC
setup. Currently assumes a single user will be used to run the VNC
server as (hard codes ports).

### full-vncserver

Server with VNC and Xfce4 desktop plus common chj packages. Note the
message about finishing the setup.

### swap

Create and activate (including adding to fstab) a swap file if none
is already active. Size is automatically chosen to be the same as
the RAM size or enough to give a total of RAM+swap of 3 GB.

### virtualmem_3GB

Enable swap if there is less than 3 GB of RAM available. (Only
provides 3 GB of virtual memory if there is at least 1 GB of RAM!
But with 512 MB of RAM Gambit compilation would be swapping so much
that more swap wouldn't be helpful anyway, so leave it at just what
the `swap` target provides.)

### nosudo

Remove `sudo` (often provided by images) since it's a security
issue. Since this will lock you out from acting as root unless you
have enabled corresponding access, you have to set
`SUDO_FORCE_REMOVE=yes` before running this target or it will
fail. If instead you want to keep `sudo` installed, set `NOSUDO=no`.

### nosudo-auto

Runs the `nosudo` target except it will force removal even without
`SUDO_FORCE_REMOVE=yes` if it can ensure that the root login can be
used: either since root was not logged in via sudo, or, it is an ssh
login, in which case the authorized_keys are copied to the root
account--NOTE that this still will you lock out if you actually log
in via password instead of a key! Still is a NOP if `NOSUDO=no` is
set.

### set-x-terminal-emulator

Set `x-terminal-emulator` in Debian's alternatives system to
`/opt/chj/bin/term`, which uses urxvt.

### firefox

Install Firefox from Debian.

### gimp

Install Gimp from Debian.

### unison

Install unison from Debian (console version).

### guix

Install guix from Debian. Upgrades system to Debian Bullseye!

### coworking-user

Create a new user for co-working (`$COWORKING_USER`, `coworking` by
default); run .chj-home/init, giving it `$CHJIZE_FULL_EMAIL` as
fullname/email input if present; copy ssh keys from root to it.

### schemen-lili

Check out and build [lili](https://github.com/pflanze/lili) as the
`schemen` user.

### root-allow-login-from-coworking-user

Allow coworking user (again, ${COWORKING_USER-coworking}) to log
into the root account via `ssh root@localhost` (as a sudo
replacement).

### coworking

Full set up of a user with Xfce desktop, various programs (like
chj-bin/fperl/emacs, Firefox, Gimp, Unison), and VNC server for
co-working. Requires VNC passwd file, run on your desktop: `scp
.vncclient-passwords/passwd root@$server:/opt/chj/chjize/tmp/`.  Set
the `CHJIZE_FULL_EMAIL` env var to the email address with full name
if you want the coworking user to be set up with it (default is
empty strings).

### schemen

Set up for Scheme mentoring: `coworking` target (see there for
details), plus Scheme.

### slim-desktop-server

`slim-desktop`, but then remove xorg and xserver-xorg packages. This
is a horrible HACK for cases where they should never be installed in
the first place but I can't figure out why they are.

### rustc

Packages for compilation/installation of programs in Rust (e.g. chj-rustbin)

### rust

Packages for development in Rust

### dev

Packages for development (including what
[cj50](https://github.com/pflanze/cj50) needs, and valgrind)

### dev-x

Packages for development including those requiring X11

### chj-rustbin-checkout

Check out [chj-rustbin](https://github.com/pflanze/chj-rustbin).

### chj-rustbin

Install [chj-rustbin](https://github.com/pflanze/chj-rustbin).

### cj-unattended-upgrades-checkout


### cj-unattended-upgrades-server

Set up cj-unattended-upgrades on a server (no claws-mail installation).

### cj-unattended-upgrades-desktop

Set up cj-unattended-upgrades on a desktop, which includes claws-mail.

## Graph of target dependencies

The targets meant to be used manually are shown in green (not used by
other targets) and blue (used by others).

<img src="graph.svg" title="Dependency graph"/>

