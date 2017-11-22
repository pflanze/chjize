
TARGETS=perhaps_aptupdate basics fperl gambit

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


clean:
	rm -f $(TARGETS)
