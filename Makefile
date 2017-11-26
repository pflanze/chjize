
TARGETS=perhaps_aptupdate debianpackages chj xfce4_load_profile load_profile moduser fperl gambit qemu

help:
	true "targets: $(TARGETS)"
	true "please specify a target"


perhaps_aptupdate:
	./bin/chjize perhaps_aptupdate

debianpackages: perhaps_aptupdate
	./bin/chjize debianpackages

chj: debianpackages
	./bin/chjize chj

xfce4_load_profile: chj
	dpkg-divert --local --rename /usr/bin/xfce4-session
	ln -s /opt/chj/bin/wrappers/xfce4-session /usr/bin/
	touch xfce4_load_profile

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
