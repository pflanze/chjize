
STATIC_TARGETS=.targets .gitignore help clean

.targets: Makefile
	bin/make-targets $(STATIC_TARGETS) < Makefile > .targets

.gitignore: .targets
	bin/make-gitignore

help: .targets .gitignore
	@echo "Usage: make <target>"
	@echo
	@echo "  Normal targets: "
	@perl -we 'print map { chomp; "    $$_\n" } <STDIN>' < .targets
	@echo
	@echo "  Special targets: "
	@echo "    clean        remove the time stamps for the above targets"
	@echo "    .gitignore   rebuild .gitignore"
	@echo "    help         this help text (includes making .gitignore)"

clean: .targets
	xargs rm -f < .targets


# Targets that are automatically listed in .targets

key:
	bin/chjize key

perhaps_aptupdate:
	bin/chjize perhaps_aptupdate

debianpackages: perhaps_aptupdate
	bin/chjize debianpackages

cplusplus: perhaps_aptupdate
	bin/chjize cplusplus

git-sign: key
	bin/chjize git-sign

chj: git-sign debianpackages
	bin/chjize chj

xfce4_load_profile: chj
	bin/chjize xfce4_load_profile

load_profile: xfce4_load_profile

moduser: chj key
	bin/chjize moduser


# XX does this need chj?
fperl: git-sign debianpackages chj
	bin/chjize fperl

gambit: git-sign cplusplus debianpackages chj
	bin/chjize gambit

qemu: git-sign gambit
	bin/chjize qemu

