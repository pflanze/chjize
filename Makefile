
TARGETS=perhaps_aptupdate basics fperl gambit qemu

help:
	true "targets: $(TARGETS)"
	true "please specify a target"


perhaps_aptupdate:
	./bin/chjize perhaps_aptupdate

basics: perhaps_aptupdate
	./bin/chjize basics

fperl: basics
	./bin/chjize fperl

gambit: basics
	./bin/chjize gambit

qemu: gambit
	./bin/chjize qemu


clean:
	rm -f $(TARGETS)
