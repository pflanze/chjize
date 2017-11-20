
TARGETS=perhaps_aptupdate basics fperl

help:
	true "targets: $(TARGETS)"
	true "please specify a target"


perhaps_aptupdate:
	./bin/chjize perhaps_aptupdate

basics: perhaps_aptupdate
	./bin/chjize basics
	touch basics

fperl: basics
	./bin/chjize fperl
	touch fperl


clean:
	rm -f $(TARGETS)
