
nothing:
	echo "please specify a target"


basics:
	./bin/chjize basics
	touch basics

fperl: basics
	./bin/chjize fperl
	touch fperl


clean:
	rm -f basics fperl
