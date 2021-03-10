# How to use: the client side

What to run, extending from the [README](README.md).

* Clone chjize to client side (desktop), verify its integrity there. 

* Create server, configure .ssh/config to define a server name like e.g. `tmp`:

        host tmp
            hostname 1.2.3.4

* Figure out which user you need to log into the server. If the server
  is from AWS, it will be `admin`, for Exoscale it will be `debian`,
  for Vultr it will be `root`. Set a variable on the client side so
  that you can copy-paste the next commands.

        export adminuser=root

* From the client side, copy over the install script:

        cd chjize
        scp install $adminuser@tmp:

* Log into server,

        ssh $adminuser@tmp
        sudo ./install 
        sudo su -
        /opt/chj/chjize/bin/chjize debconf-noninteractive moduser

    The `moduser` target changes the bash startup (and other config)
    files in `root`'s home directory (and `/etc/skel`), which sets up
    `PATH` so that `chjize` is found without using the full path.

* If this is AWS or another such root-avoiding service (`nosudo-auto`
  is also part of the `schemen` target, but is too late to allow for
  the copying of the passwd file in such a non-root based service):

        /opt/chj/chjize/bin/chjize nosudo-auto

    Now it should be possible to log in via ssh as `root`.

* On your *client side* (desktop/laptop), if you haven't already done
  it before, install `tigervnc-viewer` and create a VNC passwd file:

        sudo apt install tigervnc-viewer
        ( umask 077; mkdir ~/.vncclient-passwords/ )
        vncpasswd .vncclient-passwords/schemen-passwd
        # (say n to view-only)

* Copy over passwd file from client side:

        scp .vncclient-passwords/schemen-passwd root@tmp:/opt/chj/chjize/tmp/passwd

* Log in freshly as root to pick up the `PATH` change from `moduser` above.

        ssh root@tmp

* If wanting to use Guix, which implies updating the system to Debian sid (bullseye):

        time chjize guix

* Now the big install step can run, will take 13 minutes on t3.small
  AWS instance (2 cores, 2 GB RAM). 

        time chjize schemen

    It is the aim to allow to run `chjize -j2 schemen`, but apparently there are still cases that don't work in parallel.

* Create a client side script `tunnel-tmp`:

        #!/bin/bash

        ssh -o compression=no -L5901:localhost:5901 coworking@tmp

* Create a client side script `vnc-schemen`:

        #!/bin/bash

        xvncviewer -FullScreen -RemoteResize=0 -MenuKey F7 -shared -passwd ~/.vncclient-passwords/schemen-passwd localhost:1

* On the client side, run `tunnel-tmp` and then `vnc-schemen`.

## Other setup like:

* Configure functions that define git username and mail variables.

* Push private git repositories from client to server.

        ssh coworking@tmp
        cdnewdir foo
        git init
        
    and on client:
    
        cd foo
        git remote add tmp coworking@tmp:foo/.git
        git push tmp master # etc.
        
* Or simply install `unison-gtk` client side and use that to keep a
  synchronized copy of the server locally that you copy back after
  creating the new server.

* Add more ssh public keys

