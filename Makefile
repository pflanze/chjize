
# Backspace is being processed differently on Cygwin compared to
# Linux, this is trying to abstract it away:
BS=$(shell bin/BS)

STATIC_TARGETS=default .bs .targets .gitignore help graph.dot graph docstrings README.md auto-update clean

default: .gitignore
	@ echo "Run 'make help' for help."

.bs:
	bin/gen-BS '\\no'

.targets: Makefile
	bin/make-targets $(STATIC_TARGETS) < Makefile > .targets

.gitignore: .targets
	bin/make-gitignore $(STATIC_TARGETS)

help: .targets .gitignore docstrings
	@ echo "Usage: make <target>"
	@ echo
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

graph.dot: graph-deps .targets Makefile bin/make-graph
	bin/make-graph Makefile < .targets > graph.dot

graph: graph.dot
	display graph.dot

graph.svg: graph.dot
	dot -Tsvg *dot > graph.svg

docstrings: .targets
	bin/make-docstrings Makefile < .targets
	touch docstrings

# update README file with current docstrings
README.md: chj-bin .targets docstrings graph.svg
	cj-git-status-is-clean README.md
	bin/update-readme README.md < .targets

auto-update: README.md graph.svg
	git commit -m "auto-update" README.md graph.svg

# ------------------------------------------------------------------
# Targets that are automatically listed in `.targets`. Docstrings
# (with markdown formatting) can be given as comment lines above the
# target, without an empty line between the comments and the target or
# within.

# Install dependencies to run the `graph` target.
graph-deps: perhaps_aptupdate
	bin/chjize graph-deps

# Import cj-key.asc into the keyring of the current user.
key:
	bin/chjize key

# Run `apt-get update` unless already run in the last 24 hours.
perhaps_aptupdate:
	bin/chjize perhaps_aptupdate

# Upgrade the system (via dist-upgrade), necessary on a fresh instance
# on typical cloud hostings like Amazon's.
debian_upgrade: perhaps_aptupdate
	bin/chjize debian_upgrade

# Install `rxvt-unicode` and trim it down for security and simplicity.
urxvt: perhaps_aptupdate 
	bin/chjize urxvt

# Install my preferred Debian packages.
debianpackages: urxvt
	bin/chjize debianpackages

# Install `g++`.
cplusplus: perhaps_aptupdate
	bin/chjize cplusplus

# Check out [git-sign](https://github.com/pflanze/git-sign); used by
# most other targets.
git-sign: key
	bin/chjize git-sign

chj-perllib-checkout: .bs git-sign
	bin/chj-checkout chj-perllib-checkout https://github.com/pflanze/chj-perllib.git perllib '^r($(BS)d+)$$'

chj-perllib: chj-perllib-checkout
	bin/chjize chj-perllib

# Install [chj-bin](https://github.com/pflanze/chj-bin).
chj-bin: .bs git-sign chj-perllib
	bin/chj-checkout chj-bin https://github.com/pflanze/chj-bin.git bin '^r($(BS)d+)$$'

chj-emacs-checkout: git-sign
	bin/chj-checkout chj-emacs-checkout https://github.com/pflanze/chj-emacs.git emacs

# Install [chj-emacs](https://github.com/pflanze/chj-emacs) in
# /opt/chj/emacs/.
chj-emacs: chj-emacs-checkout
	bin/chjize chj-emacs

# Install GNU Emacs via APT.
debian-emacs:
	bin/chjize debian-emacs

# Install debian-emacs and chj-emacs targets.
emacs: debian-emacs chj-emacs

chj-fastrandom: git-sign
	bin/chj-checkout chj-fastrandom https://github.com/pflanze/fastrandom.git fastrandom

/usr/local/bin/fastrandom: chj-fastrandom
	make -C /opt/chj/fastrandom install

# Install [fastrandom](https://github.com/pflanze/fastrandom).
fastrandom: /usr/local/bin/fastrandom

# Install [cj-git-patchtool](https://github.com/pflanze/cj-git-patchtool).
cj-git-patchtool: debianpackages chj-bin git-sign
	bin/chj-checkout cj-git-patchtool https://github.com/pflanze/cj-git-patchtool.git cj-git-patchtool

# Automatically configure some (English and German speaking) locales.
locales: chj-bin
	bin/chjize locales

# Check out the last tagged versions of various repositories into
# `/opt/chj` (uses signed tags via git-sign to ensure you get what I
# signed)
chj: git-sign debianpackages chj-bin chj-emacs fastrandom cj-git-patchtool
	touch chj

# Check out [Xfce4 .config
# files](https://github.com/pflanze/dotconfig-xfce4), which are used
# by [xfce-setup](bin/xfce-setup).
dotconfig-xfce4-checkout: .bs git-sign
	bin/chj-checkout dotconfig-xfce4-checkout https://github.com/pflanze/dotconfig-xfce4.git dotconfig-xfce4 '^cj($(BS)d+)$$'

# Xfce4 desktop. Comes with `/opt/chj/chjize/bin/xfce-setup` to
# configure Xfce4 the way I like (optionally run afterwards). NOTE:
# better do not use this target directly, but rather use
# `xfce4_load_profile` or one of the `..-desktop` ones.
xfce: perhaps_aptupdate chj-bin dotconfig-xfce4-checkout
	bin/chjize xfce
	@ echo "*** NOTE: after starting Xfce, run /opt/chj/chjize/bin/xfce-setup"
	@ echo "*** to apply changes to the newly created Xfce config."

xfce4_load_profile: chj-bin xfce
	bin/chjize xfce4_load_profile

# Set up Debian so that a graphical login will read the `~/.profile`
# file (which they stopped doing at some point, dunno why); currently
# only implemented for Xfce.
load_profile: xfce4_load_profile

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
	bin/chjize moduser

# Install the [Functional Perl](http://functional-perl.org) library
# and its dependencies. WARNING: not fully secured by signatures as it
# downloads packages from CPAN whithout verifying signatures (which
# most packages don't even have). Note: requires you to enter `yes` a
# few times.
fperl: git-sign debianpackages chj-bin
	bin/chjize fperl

gambit-checkout: .bs git-sign
	bin/chj-checkout gambit-checkout https://github.com/pflanze/gambc.git gambc '^cj($(BS)d+)$$'

# Install a patched version of the Gambit Scheme system.
gambit: gambit-checkout cplusplus debianpackages chj-bin chj-emacs
	bin/chjize gambit

# Install Qemu, and
# [cj-qemucontrol](https://github.com/pflanze/cj-qemucontrol).
qemu: git-sign gambit
	bin/chjize qemu

# Xfce4, desktop packages.
slim-desktop: chj xfce4_load_profile
	bin/chjize full-desktop

# `slim-desktop`, but also removes pulseaudio and installs jack, and
# removes the login managers. Xfce4 has to be started via `startx`
# from the console after this! (That latter part was a hack to work
# around some issues in Debian stretch / get what I wanted.)
full-desktop: slim-desktop
	bin/chjize slim-desktop

# The `full-desktop` target but also runs `apt-get autoremove` to free
# up the space taken by now unused packages.
full-desktop_autoremove: full-desktop
	apt-get autoremove

# Install and configure a local dns resolver (unbound).
dnsresolver:
	bin/chjize dnsresolver

# Install mercurial, and hg-fast-export from either Debian or upstream
# source.
mercurial: chj-bin
	bin/chjize mercurial

# Ensure basic system readyness.
system: debian_upgrade locales

_slim-vncserver: perhaps_aptupdate slim-desktop chj-bin
	bin/chjize slim-vncserver

# Server side VNC setup, to be used via client side VNC
# setup. Currently assumes a single user will be used to run the VNC
# server as (hard codes ports).
slim-vncserver: _slim-vncserver
	@ echo "*** NOTE: xfce4 is not included in this target; run the full-vncserver "
	@ echo "*** target for the whole convenient setup."

# Server with VNC and Xfce4 desktop plus common chj packages. Note the
# echoed text about finishing the setup.
full-vncserver: _slim-vncserver debianpackages urxvt system
	@ echo "*** Now please run /opt/chj/chjize/bin/slim-vncserver-setup as the user"
	@ echo "*** that you want to access from the VNC connection (also, first"
	@ echo "*** run /opt/chj/chjize/bin/mod-user as that user if 'make moduser' was"
	@ echo "*** not run as root before creating that user)."

# Client side VNC setup.
vncclient: perhaps_aptupdate
	bin/chjize vncclient


# Create and activate (including adding to fstab) a swap file if none
# is already active. Size is automatically chosen from RAM size.
swap: chj-bin
	bin/chjize swap

# Remove `sudo` (often provided by images) since it's a security issue.
nosudo:
	bin/chjize nosudo

# Full set up of a VNC server for Scheme mentoring.
schememen: system full-vncserver swap nosudo gambit chj-emacs
	apt-get clean

