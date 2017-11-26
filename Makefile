
TARGETS=perhaps_aptupdate debianpackages chj moduser fperl gambit qemu

help:
	true "targets: $(TARGETS)"
	true "please specify a target"


perhaps_aptupdate:
	./bin/chjize perhaps_aptupdate

debianpackages: perhaps_aptupdate
	./bin/chjize debianpackages

chj: debianpackages
	./bin/chjize chj

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
