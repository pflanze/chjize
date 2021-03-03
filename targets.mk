
# Backspace is being processed differently on Cygwin compared to
# Linux, this is trying to abstract it away:
BS=$(shell sbin/BS)

STATIC_TARGETS=default .bs .targets .gitignore help graph.dot graph docstrings README.md auto-update clean install

# No 'better' way to generate tmp/ *before* `schemen` target is
# started (?). `default` is called by `install` script.
default: .gitignore tmp/.gitignore
	@ echo "Run 'chjize -h' for help."

.bs:
	sbin/gen-BS '\\no'

.targets: targets.mk
	sbin/make-targets $(STATIC_TARGETS) < targets.mk > .targets

.gitignore: .targets
	sbin/make-gitignore $(STATIC_TARGETS)

tmp/.gitignore:
	sbin/create-tmp


help: .targets docstrings default
	@ echo "  Normal targets: "
	@ perl -we 'print map { chomp; my $$file= ".docstrings/$$_"; my $$in; open $$in, "<", $$file or undef $$in; ("\n    $$_\n", $$in ? map { "      $$_" } <$$in> : ()) } <STDIN>' < .targets
	@ echo
	@ echo "  Special targets: "
	@ echo "    clean        remove the time stamps for the above targets"
	@ echo "    .gitignore   rebuild .gitignore"
	@ echo "    help         this help text (includes making .gitignore)"
	@ echo "    graph        show the graph of dependencies; the targets meant"
	@ echo "                 to be run manually are in green (not used by other"
	@ echo "                 targets) and blue (used by others)."

clean: .targets
	xargs rm -f < .targets

graph.dot: graph-deps .targets targets.mk sbin/make-graph
	sbin/make-graph targets.mk < .targets > graph.dot

graph: graph.dot
	display graph.dot

graph.svg: graph.dot
	dot -Tsvg *dot > graph.svg

docstrings: .targets
	sbin/make-docstrings targets.mk < .targets
	touch docstrings

# update README file with current docstrings
README.md: chj-bin .targets docstrings graph.svg
	cj-git-status-is-clean README.md
	sbin/update-readme README.md < .targets

install: README.md
	sbin/action install

auto-update: README.md graph.svg install
	git commit -m "auto-update" README.md graph.svg install || true

# ------------------------------------------------------------------
# Targets that are automatically listed in `.targets`. Docstrings
# (with markdown formatting) can be given as comment lines above the
# target, without an empty line between the comments and the target or
# within.

# Install dependencies to run the `graph` target.
graph-deps: perhaps_aptupdate
	sbin/action graph-deps

# Import cj-key.asc into the keyring of the current user.
key:
	sbin/action key

# Run `apt-get update` unless already run in the last 24 hours.
perhaps_aptupdate:
	sbin/action perhaps_aptupdate

# Upgrade the system (via dist-upgrade), necessary on a fresh instance
# on typical cloud hostings like Amazon's.
debian_upgrade: perhaps_aptupdate
	sbin/action debian_upgrade

# Install `rxvt-unicode` and trim it down for security and simplicity.
urxvt: perhaps_aptupdate 
	sbin/action urxvt

# Install my preferred Debian packages.
debianpackages: urxvt
	sbin/action debianpackages

# Install `g++`.
cplusplus: perhaps_aptupdate
	sbin/action cplusplus

# Check out [git-sign](https://github.com/pflanze/git-sign); used by
# most other targets.
git-sign: key
	sbin/action git-sign

chj-perllib-checkout: .bs git-sign
	bin/chj-checkout chj-perllib-checkout https://github.com/pflanze/chj-perllib.git perllib '^r($(BS)d+)$$'

# Install (via symlink)
# [chj-perllib](https://github.com/pflanze/chj-perllib). These depend
# on `fperl` now, thus that is installed as well.
chj-perllib: chj-perllib-checkout fperl
	sbin/action chj-perllib
# ^ XX would fperl-noinstall be enough? It would be preferable.

# Install [chj-bin](https://github.com/pflanze/chj-bin).
chj-bin: .bs git-sign chj-perllib
	bin/chj-checkout chj-bin https://github.com/pflanze/chj-bin.git bin '^r($(BS)d+)$$'

chj-emacs-checkout: git-sign
	bin/chj-checkout chj-emacs-checkout https://github.com/pflanze/chj-emacs.git emacs

# Install [chj-emacs](https://github.com/pflanze/chj-emacs) in
# /opt/chj/emacs/.
chj-emacs: chj-emacs-checkout
	sbin/action chj-emacs

# Install GNU Emacs via APT.
debian-emacs:
	sbin/action debian-emacs

# Install debian-emacs and chj-emacs targets.
emacs: debian-emacs chj-emacs
	touch emacs

chj-fastrandom: git-sign
	bin/chj-checkout chj-fastrandom https://github.com/pflanze/fastrandom.git fastrandom

/usr/local/bin/fastrandom: chj-fastrandom
	make -C /opt/chj/fastrandom install

# Install [fastrandom](https://github.com/pflanze/fastrandom).
fastrandom: /usr/local/bin/fastrandom
	touch fastrandom

# Install [cj-git-patchtool](https://github.com/pflanze/cj-git-patchtool).
cj-git-patchtool: debianpackages chj-bin git-sign
	bin/chj-checkout cj-git-patchtool https://github.com/pflanze/cj-git-patchtool.git cj-git-patchtool

# Automatically configure some (English and German speaking) locales.
locales: chj-bin
	sbin/action locales

# Automatically configure debconf to be in Noninteractive mode (run
# this to avoid other targets waiting for inputs; also, it will be the
# only mode that works with -j2).
debconf-noninteractive:
	sbin/action debconf-noninteractive

# Check out the last tagged versions of various repositories into
# `/opt/chj` (uses signed tags via git-sign to ensure you get what I
# signed)
chj: git-sign debianpackages chj-bin chj-emacs fastrandom cj-git-patchtool
	touch chj

# Check out [Xfce4 .config
# files](https://github.com/pflanze/dotconfig-xfce4), which are used
# by [chjize-xfce-setup](bin/chjize-xfce-setup).
dotconfig-xfce4-checkout: .bs git-sign
	bin/chj-checkout dotconfig-xfce4-checkout https://github.com/pflanze/dotconfig-xfce4.git dotconfig-xfce4 '^cj($(BS)d+)$$'

# Xfce4 desktop. Comes with `/opt/chj/chjize/bin/chjize-xfce-setup` to
# configure Xfce4 the way I like (optionally run afterwards). NOTE:
# better do not use this target directly, but rather use
# `xfce4_load_profile` or one of the `..-desktop` ones.
xfce: perhaps_aptupdate chj-bin dotconfig-xfce4-checkout
	sbin/action xfce

xfce4_load_profile: chj-bin xfce
	sbin/action xfce4_load_profile

# Set up Debian so that a graphical login will read the `~/.profile`
# file (which they stopped doing at some point, dunno why); currently
# only implemented for Xfce.
load_profile: xfce4_load_profile
	touch load_profile

# Modify the `/root`, `/etc/skel`, and if present `/home/chris`
# directories to use a checkout of
# [chj-home](https://github.com/pflanze/chj-home); it should safely
# store previous versions of your files in the Git repository that's
# at this place before checking out my versions, see them via `gitk
# --all`. This also sets up emacs to work nicely with Gambit, see
# below. Note: if there is a `.git` directory in those directories
# before, it will ask whether to continue by first moving those to
# `/root/.trash/`.
#
# If you want to modify a particular user's home without affecting the
# other users, instead run `/opt/chj/chjize/bin/mod-user` as that user
# (in its home dir)
moduser: chj key
	sbin/action moduser

# Install the [Functional Perl](http://functional-perl.org) library
# and its dependencies. Currently installs dependencies only from
# Debian, and Functional Perl itself via Git and checks the signature,
# thus is secure and won't ask questions (assuming
# `debconf-noninteractive` was run).  Does not actually run `make
# install`, thus Programs using functional-perl need to `use lib
# /opt/functional-perl/lib;`! For a full installation, use the `fperl`
# target.
fperl-noinstall: git-sign
	sbin/action fperl-noinstall

# This is the `fperl-noinstall` target but also *does* run `make
# install`. (This still does not access CPAN, and thus is still
# secure.)
fperl: fperl-noinstall
	sbin/action fperl


gambit-checkout: .bs git-sign
	bin/chj-checkout gambit-checkout https://github.com/pflanze/gambc.git gambc '^cj($(BS)d+)$$'

# Install a patched version of the Gambit Scheme system.
gambit: gambit-checkout cplusplus debianpackages chj-bin chj-emacs virtualmem_3GB
	sbin/action gambit

# Install Qemu, and
# [cj-qemucontrol](https://github.com/pflanze/cj-qemucontrol).
qemu: git-sign gambit
	sbin/action qemu

# Xfce4, desktop packages.
slim-desktop: chj set-x-terminal-emulator xfce4_load_profile
	sbin/action slim-desktop

# `slim-desktop`, but also removes pulseaudio and installs jack, and
# removes the login managers. Xfce4 has to be started via `startx`
# from the console after this! (That latter part was a hack to work
# around some issues in Debian stretch / get what I wanted.)
full-desktop: slim-desktop
	sbin/action full-desktop

# The `full-desktop` target but also runs `apt-get autoremove` to free
# up the space taken by now unused packages.
full-desktop_autoremove: full-desktop
	sbin/action full-desktop_autoremove

# Install and configure a local dns resolver (unbound).
dnsresolver:
	sbin/action dnsresolver

# Install mercurial, and hg-fast-export from either Debian or upstream
# source.
mercurial: chj-bin
	sbin/action mercurial

# Ensure basic system readyness.
system: debian_upgrade locales
	touch system

# Server side VNC setup, to be used via client side VNC
# setup. Currently assumes a single user will be used to run the VNC
# server as (hard codes ports).
slim-vncserver: perhaps_aptupdate slim-desktop chj-bin
	sbin/action slim-vncserver

# Server with VNC and Xfce4 desktop plus common chj packages. Note the
# message about finishing the setup.
full-vncserver: slim-vncserver debianpackages system
	sbin/action full-vncserver

# Client side VNC setup.
vncclient: perhaps_aptupdate
	sbin/action vncclient


# Create and activate (including adding to fstab) a swap file if none
# is already active. Size is automatically chosen to be the same as
# the RAM size or enough to give a total of RAM+swap of 3 GB.
swap: chj-bin
	sbin/action swap

# Enable swap if there is less than 3 GB of RAM available. (Only
# provides 3 GB of virtual memory if there is at least 1 GB of RAM!
# But with 512 MB of RAM Gambit compilation would be swapping so much
# that more swap wouldn't be helpful anyway, so leave it at just what
# the `swap` target provides.)
virtualmem_3GB: chj-bin
	sbin/action virtualmem_3GB

# Remove `sudo` (often provided by images) since it's a security
# issue. Since this will lock you out from acting as root unless you
# have enabled corresponding access, you have to set
# `SUDO_FORCE_REMOVE=yes` before running this target or it will
# fail. If instead you want to keep `sudo` installed, set `NOSUDO=no`.
nosudo:
	sbin/action nosudo

# Runs the `nosudo` target except it will force removal even without
# `SUDO_FORCE_REMOVE=yes` if it can ensure that the root login can be
# used: either since root was not logged in via sudo, or, it is an ssh
# login, in which case the authorized_keys are copied to the root
# account--NOTE that this still will you lock out if you actually log
# in via password instead of a key! Still is a NOP if `NOSUDO=no` is
# set.
nosudo-auto:
	sbin/action nosudo-auto

# Set `x-terminal-emulator` in Debian's alternatives system to
# `/opt/chj/bin/term`, which uses urxvt.
set-x-terminal-emulator: urxvt chj-bin
	sbin/action set-x-terminal-emulator

# Install Firefox from Debian.
firefox: perhaps_aptupdate
	sbin/action firefox

# Install unison from Debian (console version).
unison: perhaps_aptupdate
	sbin/action unison

# Install guix from Debian. Upgrades system to Debian Bullseye!
guix: perhaps_aptupdate bullseye
	sbin/action guix

# Create `schemen` user, copy ssh keys from root to it.
schemen-user: moduser
	sbin/action schemen-user

# Check out and build [lili](https://github.com/pflanze/lili) as the
# `schemen` user.
schemen-lili: schemen-user gambit chj-emacs
	sbin/action schemen-lili
# ^ chj-emacs for /opt/chj/emacs/bin/gam-emacs

# Full set up of a VNC server for Scheme mentoring. Requires VNC
# passwd file, first run on server: `( umask 077; mkdir tmp )` then
# on your desktop: `scp .vncclient-passwords/passwd
# root@tmp:/opt/chj/chjize/tmp/`.
schemen: tmp/passwd system full-vncserver nosudo-auto gambit emacs schemen-user schemen-lili firefox unison
	sbin/action schemen

schemen-finish:
	sbin/action schemen-finish

# Remove xorg and xserver-xorg packages. This is a horrible HACK for
# cases where they should never be installed in the first place but I
# can't figure out why they are. (This is called from within the
# slim-desktop rule.)
remove-xserver:
	sbin/action remove-xserver


# Changes /etc/apt/sources.list to point to bullseye instead of buster
sources-bullseye: chj-bin
	sbin/action sources-bullseye

# Upgrade a Debian system running Buster to Bullseye (does include
# running `apt-get update` as part of the action).
bullseye: sources-bullseye
	sbin/action bullseye
# (Depending on perhaps_aptupdate would be wrong, both because that
# would not run if it ran within the last 24 hours, but also because
# there's no way to specify it running *after* sources-bullseye.)
