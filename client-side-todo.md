# How to use: the client side

What to run, extending from the [README](README.md).

* Clone chjize to client side (desktop), verify its integrity there.

* Create server, configure .ssh/config to define a server name like e.g. `tmp`:

        host tmp
            hostname 1.2.3.4

* If the server is from AWS, it will not allow root logins but only
  admin. Copy over install script:

        scp /opt/chj/chjize/install admin@tmp:

* Log into server,

        ssh admin@tmp
        sudo ./install 
        sudo su -
        PATH=/opt/chj/chjize/bin:$PATH
        chjize debconf-noninteractive

* If this is AWS or another such root-avoiding service (`nosudo-auto`
  is also part of the `schemen` target, but is too late to allow for
  the copying of the passwd file in such a non-root based service):

        chjize nosudo-auto

  Now it should be possible to log in via ssh as `root`.

* If you haven't already done before, install `tigervnc-viewer` and
  create a VNC passwd file on your client side (desktop/laptop):

        sudo apt install tigervnc-viewer
        vncpasswd
        # (say n to view-only)
        ( umask 077; mkdir ~/.vncclient-passwords/ )
        mv .vnc/passwd .vncclient-passwords/schemen-passwd

* Copy over passwd file from client side:

        scp .vncclient-passwords/schemen-passwd root@tmp:/opt/chj/chjize/tmp/passwd

* Now the big install step can run, will take 13 minutes on t3.small AWS instance (2 cores, 2 GB RAM):

        ssh root@tmp
        PATH=/opt/chj/chjize/bin:$PATH
        time chjize schemen

    It is the aim to allow to run `chjize -j2 schemen`, but apparently there are still cases that don't work in parallel.

* Create a client side script `tunnel-tmp`:

        #!/bin/bash

        ssh -o compression=no -L5901:localhost:5901 schemen@tmp

* Create a client side script `vnc-schemen`:

        #!/bin/bash

        xvncviewer -FullScreen -RemoteResize=0 -MenuKey F7 -shared -passwd ~/.vncclient-passwords/schemen-passwd localhost:1

* When the big install step is finished, run `tunnel-tmp` and then `vnc-schemen`. Click on the mentioned button, exit the VNC client. On the server run:

        chjize schemen-finish

## Other setup like:

* Configure functions that define git username and mail variables.

* Push private git repositories from client to server.

        ssh schemen@tmp
        cdnewdir foo
        git init
        
    and on client:
    
        cd foo
        git remote add tmp schemen@tmp:foo/.git
        git push tmp master # etc.
        
* Or simply install `unison-gtk` client side and use that to keep a
  synchronized copy of the server locally that you copy back after
  creating the new server.

* Add more ssh public keys

