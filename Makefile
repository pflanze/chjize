
TARGETS=perhaps_aptupdate debianpackages chj xfce4_load_profile load_profile moduser fperl gambit qemu

help:
	@echo "Usage: make <target>"
	@echo
	@echo "  Normal targets: "
	@perl -we 'print map { "    $$_\n" } @ARGV' $(TARGETS)
	@echo
	@echo "  Special targets: "
	@echo "    clean        remove the time stamps for the above targets"
	@echo "    .gitignore   rebuild .gitignore"

.gitignore: Makefile
	bin/make-gitignore $(TARGETS)

perhaps_aptupdate:
	./bin/chjize perhaps_aptupdate

debianpackages: perhaps_aptupdate
	./bin/chjize debianpackages

chj: debianpackages
	./bin/chjize chj

xfce4_load_profile: chj
	./bin/chjize xfce4_load_profile

load_profile: xfce4_load_profile

moduser: chj
	./bin/chjize moduser


# XX does this need chj?
fperl: debianpackages chj
	./bin/chjize fperl

gambit: debianpackages
	./bin/chjize gambit

qemu: gambit
	./bin/chjize qemu


clean:
	rm -f $(TARGETS)
