
# The default recipe: take the action with the same name as the
# target, with no arguments.
% ::
	sbin/action $@

# Backslash is being processed differently on Cygwin compared to
# Linux, this is trying to abstract it away:
BS=$(shell sbin/BS)

STATIC_TARGETS=default .bs .targets .gitignore help graph.dot graph docstrings README.md auto-update clean install-chjize

# No 'better' way to generate tmp/ *before* `schemen` target is
# started (?). `default` is called by `install` script.
default: .gitignore tmp/.gitignore
	@ echo "Run 'chjize -h' for help."

release: auto-update
	@true

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

graph: graph.svg
	eog graph.svg

graph.svg: graph.dot
	dot -Tsvg *dot > graph.svg

docstrings: .targets
	sbin/make-docstrings targets.mk < .targets
	touch docstrings

# update README file with current docstrings
README.md: chj-bin .targets docstrings graph.svg
	cj-git-status-is-clean README.md
	sbin/update-readme README.md < .targets

install-chjize: README.md

auto-update: README.md graph.svg install-chjize
	git commit -m "auto-update" README.md graph.svg install-chjize || true

# ------------------------------------------------------------------
# Targets that are automatically listed in `.targets`. Docstrings
# (with markdown formatting) can be given as comment lines above the
# target, without an empty line between the comments and the target or
# within.

# Install dependencies to run the `graph` target.
graph-deps:

# Import cj-key.asc into the keyring of the current user.
key:

# Upgrade the system (via dist-upgrade), necessary on a fresh instance
# on typical cloud hostings like Amazon's.
debian_upgrade:

# Install some fonts, amongst them Inconsolata for urxvt.
fonts:

# Install `rxvt-unicode` and trim it down for security and simplicity.
urxvt: fonts

# Install my preferred Debian packages that are command-line only.
debianpackages:

# Install my preferred Debian packages requiring X11.
debianpackages-x:

# Install the Perl packages from Debian needed for chj-bin.
chj-perl-debian:

# Install the Perl packages from Debian needed for fperl.
fperl-perl-debian:

# Install Debian packages around image processing (like optipng, gimp, mat2)
imageprocessing:

# Install `g++`.
cplusplus-compiler:

# Packages for development in C++.
cplusplus: cplusplus-compiler emacs-full
	touch cplusplus

# Check out [git-sign](https://github.com/pflanze/git-sign); used by
# most other targets.
git-sign: key

chj-perllib-checkout: .bs git-sign
	bin/chj-checkout $@ https://github.com/pflanze/chj-perllib.git perllib '^r($(BS)d+)$$'

# Install (via symlink)
# [chj-perllib](https://github.com/pflanze/chj-perllib). These depend
# on `fperl` now, thus that is installed as well.
chj-perllib: chj-perllib-checkout chj-perl-debian fperl
# ^ fperl-noinstall is (currently) not enough, and adding explicit
# "use lib" statements in pretty much all Perl scripts in chj-bin
# would be ugly, and, just accept it needs an installation step like
# normal software, *or* an env var, this *is* how it should be.

chj-bin-checkout: .bs git-sign
	bin/chj-checkout $@ https://github.com/pflanze/chj-bin.git bin '^r($(BS)d+)$$'

# Install [chj-bin](https://github.com/pflanze/chj-bin).
chj-bin: chj-bin-checkout chj-perllib chj-perl-debian
	touch chj-bin

# Install GNU Emacs via APT.
debian-emacs:

# Install debian-emacs. 
emacs: debian-emacs
	@echo "NOTE: chj-emacs will be installed per-user when you run mod-user."
	touch emacs

# Checkout `chj-emacs`. Does not run `make` in it.
chj-emacs: .bs git-sign
	bin/chj-checkout $@ https://github.com/pflanze/chj-emacs.git chj-emacs '^v($(BS)d+)$$'

# Install emacs, including cloning `chj-emacs` in `/opt/chj` and
# running `make` which installs further Debian packages (including
# GHC, currently); you still also need to run `make` per user in
# `.chj-emacs` after `mod-user` to get the local checkouts and
# symlinks, though.
emacs-full: emacs chj-emacs


# Install wget from Debian
wget:

get_codium_deb: wget

# Install vscode from a binary off GitHub, WARNING: just hashed once
# on first retrieval. HACK, unfinished: needs `slim-desktop` or
# similar to be installed or add exact dependencies to the action, or
# run apt-get -f install for fixing it up.
vscodium: get_codium_deb

fastrandom-checkout: git-sign
	bin/chj-checkout $@ https://github.com/pflanze/fastrandom.git fastrandom

/usr/local/bin/fastrandom: fastrandom-checkout
	make -C /opt/chj/fastrandom install

# Install [fastrandom](https://github.com/pflanze/fastrandom).
fastrandom: /usr/local/bin/fastrandom
	touch fastrandom

# Install [cj-git-patchtool](https://github.com/pflanze/cj-git-patchtool).
cj-git-patchtool: .bs debianpackages chj-bin git-sign
	bin/chj-checkout $@ https://github.com/pflanze/cj-git-patchtool.git cj-git-patchtool '^v($(BS)d+$(BS).$(BS)d+$(BS).$(BS)d+)$$'
# ^ does it really need debianpackages ?
#   Well, debianpackages-x even for usability, but only optionally.

# Automatically configure some (English and German speaking) locales.
locales: chj-bin

# Automatically configure debconf to be in Noninteractive mode (run
# this to avoid other targets waiting for inputs; also, it will be the
# only mode that works with -j2).
debconf-noninteractive:

# Check out the last tagged versions of various repositories into
# `/opt/chj` (uses signed tags via git-sign to ensure you get what I
# signed)
chj: git-sign debianpackages chj-bin emacs fastrandom cj-git-patchtool
	touch chj

# Chj including parts requiring X11
chj-x: chj debianpackages-x

# Check out [Xfce4 .config
# files](https://github.com/pflanze/dotconfig-xfce4), which are used
# by [chjize-xfce-setup](bin/chjize-xfce-setup).
dotconfig-xfce4-checkout: .bs git-sign
	bin/chj-checkout $@ https://github.com/pflanze/dotconfig-xfce4.git dotconfig-xfce4 '^cj($(BS)d+)$$'

# Xfce4 desktop, local. Comes with
# `/opt/chj/chjize/bin/chjize-xfce-setup` to configure Xfce4 the way I
# like (optionally run afterwards--see message emitted by this target
# for some more detail). NOTE: better do not use this target directly,
# but rather use `xfce4_load_profile` or one of the `..-desktop` ones.
xfce-local: chj-bin dotconfig-xfce4-checkout
	sbin/action $@ xfce local

# Same as xfce-local, but tries to avoid installing the xserver
# packages.
xfce-server: chj-bin dotconfig-xfce4-checkout
	sbin/action $@ xfce server

xfce4_load_profile: chj-bin xfce-server

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


# `Module::Locate` has no signature on CPAN, thus I forked, verified
# and signed it myself.
Module-Locate-checkout: .bs git-sign
	bin/chj-checkout $@ https://github.com/pflanze/Module-Locate.git Module-Locate '^cj($(BS)d+)$$' '>=' cj3

Module-Locate: Module-Locate-checkout fperl-perl-debian

Test-Pod-Snippets-checkout: .bs git-sign
	bin/chj-checkout $@ https://github.com/pflanze/test-pod-snippets.git test-pod-snippets '^cj($(BS)d+)$$' '>=' cj3

# `Test::Pod::Snippets`, has a CPAN signature but for ease of checking
# I forked, verified and signed it myself. Depends on
# libpod-parser-perl from fperl-perl-debian.
Test-Pod-Snippets: Test-Pod-Snippets-checkout fperl-perl-debian Module-Locate

# `fperl-noinstall` and the necessary dependencies to run its test
# suite. Run the test suite.
fperl-test: fperl-noinstall chj-perl-debian fperl-perl-debian Test-Pod-Snippets

# Install the [Functional Perl](http://functional-perl.org) library
# and its dependencies. Currently installs dependencies only from
# Debian, and Functional Perl itself via Git and checks the signature,
# thus is secure and won't ask questions (assuming
# `debconf-noninteractive` was run).  Does not actually run `make
# install`, thus Programs using functional-perl need to `use lib
# /opt/functional-perl/lib;`! For a full installation, use the `fperl`
# target.
fperl-noinstall: git-sign fperl-perl-debian

# This is the `fperl-noinstall` target but also *does* run `make
# install`. (This still does not access CPAN, and thus is still
# secure.)
fperl: fperl-noinstall


gambit-checkout: .bs git-sign
	bin/chj-checkout $@ https://github.com/pflanze/gambc.git gambc '^cj($(BS)d+)$$'

# Install a patched version of the Gambit Scheme system.
gambit: gambit-checkout cplusplus-compiler debianpackages chj-bin virtualmem_3GB
# Does it really depend on debianpackages?

cj-qemucontrol-checkout: .bs git-sign
	bin/chj-checkout $@ https://github.com/pflanze/cj-qemucontrol.git cj-qemucontrol '^v($(BS)d+)$$'

# Install [cj-qemucontrol](https://github.com/pflanze/cj-qemucontrol).
cj-qemucontrol: cj-qemucontrol-checkout gambit
	touch $@

# Install `dnsmasq` from Debian. (Used by `serve-dhcp` from
# `chj-bin`.)
dnsmasq:

# Install Qemu, cj-qemucontrol, dnsmasq, and run
# [qemu-adduser](bin/qemu-adduser) to create the user specified in
# `$QEMU_USER` or the default `qemu` if not given, and give it the
# necessary permissions.
qemu: cj-qemucontrol dnsmasq

# Desktop things still needed in a chroot (via `chrootlogin` tool from
# chj-bin) running inside a deskop which is installed on the host.
chroot-desktop: system chj-x set-x-terminal-emulator
	touch chroot-desktop

# Xfce4, desktop packages.
slim-desktop: chroot-desktop xfce4_load_profile cj-unattended-upgrades-desktop firefox

# `slim-desktop`, but also setup for real hardware desktops/laptops (not VPSs or VMs).
real-desktop: system slim-desktop

# `linux-perf` and perhaps in the future other performance benchmarking tooling.
perf:

# `slim-desktop`, but also removes pulseaudio and installs jack, and
# removes the login managers. Xfce4 has to be started via `startx`
# from the console after this! (That latter part was a hack to work
# around some issues in Debian stretch / get what I wanted.)
full-desktop: slim-desktop

# The `full-desktop` target but also runs `apt-get autoremove` to free
# up the space taken by now unused packages.
full-desktop_autoremove: full-desktop

# Install and configure a local dns resolver (unbound).
dnsresolver:

# Install mercurial, and hg-fast-export from either Debian or upstream
# source.
mercurial: chj-bin

# Install earlyoom (and, todo: configure it)
earlyoom:

# Security relevant actions, like divert cupsd so it never runs by accident.
security:

# Ensure basic system readyness for any system.
system: debian_upgrade locales cj-unattended-upgrades-server earlyoom security
	touch system

# fail2ban, with some config tweaks for stricter SSH blocking
fail2ban: 

# SSH service
ssh-server: fail2ban


# Server side VNC setup, to be used via client side VNC
# setup. Currently assumes a single user will be used to run the VNC
# server as (hard codes ports).
slim-vncserver: slim-desktop-server chj-bin

# Server with VNC and Xfce4 desktop plus common chj packages. Note the
# message about finishing the setup.
full-vncserver: slim-vncserver debianpackages-x


# Create and activate (including adding to fstab) a swap file if none
# is already active. Size is automatically chosen to be the same as
# the RAM size or enough to give a total of RAM+swap of 3 GB.
swap: chj-bin

# Enable swap if there is less than 3 GB of RAM available. (Only
# provides 3 GB of virtual memory if there is at least 1 GB of RAM!
# But with 512 MB of RAM Gambit compilation would be swapping so much
# that more swap wouldn't be helpful anyway, so leave it at just what
# the `swap` target provides.)
virtualmem_3GB: chj-bin

# Remove `sudo` (often provided by images) since it's a security
# issue. Since this will lock you out from acting as root unless you
# have enabled corresponding access, you have to set
# `SUDO_FORCE_REMOVE=yes` before running this target or it will
# fail. If instead you want to keep `sudo` installed, set `NOSUDO=no`.
nosudo:

# Runs the `nosudo` target except it will force removal even without
# `SUDO_FORCE_REMOVE=yes` if it can ensure that the root login can be
# used: either since root was not logged in via sudo, or, it is an ssh
# login, in which case the authorized_keys are copied to the root
# account--NOTE that this still will you lock out if you actually log
# in via password instead of a key! Still is a NOP if `NOSUDO=no` is
# set.
nosudo-auto:

# Set `x-terminal-emulator` in Debian's alternatives system to
# `/opt/chj/bin/term`, which uses urxvt.
set-x-terminal-emulator: urxvt chj-bin

# Install Firefox from Debian.
firefox:

# Install Gimp from Debian.
gimp:

# Install unison from Debian (console version).
unison:

# Install guix from Debian. Upgrades system to Debian Bullseye!
guix: bullseye

# Create a new user for co-working (`$COWORKING_USER`, `coworking` by
# default); run .chj-home/init, giving it `$CHJIZE_FULL_EMAIL` as
# fullname/email input if present; copy ssh keys from root to it.
coworking-user:
	sbin/action $@ ssh-user $${COWORKING_USER-coworking}

# Check out and build [lili](https://github.com/pflanze/lili) as the
# `schemen` user.
schemen-lili: coworking-user gambit
	sbin/action $@ schemen-lili $${COWORKING_USER-coworking}

# Allow coworking user (again, ${COWORKING_USER-coworking}) to log
# into the root account via `ssh root@localhost` (as a sudo
# replacement).
root-allow-login-from-coworking-user: coworking-user

tmp/passwd:
	@echo "Missing file $@"
	@false

# Full set up of a user with Xfce desktop, various programs (like
# chj-bin/fperl/emacs, Firefox, Gimp, Unison), and VNC server for
# co-working. Requires VNC passwd file, run on your desktop: `scp
# .vncclient-passwords/passwd root@$server:/opt/chj/chjize/tmp/`.  Set
# the `CHJIZE_FULL_EMAIL` env var to the email address with full name
# if you want the coworking user to be set up with it (default is
# empty strings).
coworking: tmp/passwd full-vncserver coworking-user root-allow-login-from-coworking-user nosudo-auto emacs firefox unison gimp dev-x
	sbin/action $@ vnc-setup $${COWORKING_USER-coworking}

# Set up for Scheme mentoring: `coworking` target (see there for
# details), plus Scheme.
schemen: coworking emacs schemen-lili
	touch schemen

# `slim-desktop`, but then remove xorg and xserver-xorg packages. This
# is a horrible HACK for cases where they should never be installed in
# the first place but I can't figure out why they are.
slim-desktop-server: slim-desktop

# Packages for compilation/installation of programs in Rust (e.g. chj-rustbin)
rustc: 

# Packages for development in Rust
rust: emacs-full rustc

# Packages for development (including what
# [cj50](https://github.com/pflanze/cj50) needs, and valgrind, but
# excluding documentation packages like pandoc)
dev: debianpackages

# Packages for development including those requiring X11
dev-x: dev debianpackages-x

# Packages for "documentation development": pandoc, and
# debianpackages.
dev-doc: debianpackages

# Check out [chj-rustbin](https://github.com/pflanze/chj-rustbin).
chj-rustbin-checkout: rustc .bs git-sign
	bin/chj-checkout $@ https://github.com/pflanze/chj-rustbin.git chj-rustbin '^cj($(BS)d+)$$'

# Install [chj-rustbin](https://github.com/pflanze/chj-rustbin).
chj-rustbin: chj-rustbin-checkout



cj-unattended-upgrades-checkout: git-sign .bs git-sign
	bin/chj-checkout $@ https://github.com/pflanze/cj-unattended-upgrades.git cj-unattended-upgrades '^cj($(BS)d+)$$'

# Set up cj-unattended-upgrades on a server (no claws-mail installation).
cj-unattended-upgrades-server: cj-unattended-upgrades-checkout chj-bin 

# Set up cj-unattended-upgrades on a desktop, which includes claws-mail.
cj-unattended-upgrades-desktop: cj-unattended-upgrades-server
