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
        export server=tmp

* From the client side, copy over the install-chjize script:

        cd chjize
        scp install-chjize $adminuser@$server:

* Log into server,

        ssh $adminuser@$server
        sudo ./install-chjize 
        sudo su -
        /opt/chj/chjize/bin/chjize debconf-noninteractive

    The `moduser` target changes the bash startup (and other config)
    files in `root`'s home directory (and `/etc/skel`), which sets up
    `PATH` so that `chjize` is found without using the full path.
    
        /opt/chj/chjize/bin/chjize moduser

* If this is AWS or another such root-avoiding service (`nosudo-auto`
  is also part of the `coworking` target, but is too late to allow for
  the copying of the passwd file in such a non-root based service):

        /opt/chj/chjize/bin/chjize nosudo-auto

    Now it should be possible to log in via ssh as `root`.

* On your *client side* (desktop/laptop), if you haven't already done
  it before and you're on a Linux(-like) system:
  
    1. install `tigervnc-viewer` and `tigervnc-common` and create a
       VNC passwd file:

            sudo apt install tigervnc-viewer tigervnc-common
            ( umask 077; mkdir ~/.vncclient-passwords/ )
            vncpasswd .vncclient-passwords/coworking-passwd
            # (say n to view-only)

    2. Create a client side script `tunnel-tmp`:

            #!/bin/bash

            ssh -o compression=no -L5901:localhost:5901 coworking@tmp

    3. Create a client side script `vnc-coworking`:

            #!/bin/bash

            xvncviewer -FullScreen -RemoteResize=0 -MenuKey F7 -shared -passwd ~/.vncclient-passwords/coworking-passwd localhost:1

        Note: xvncviewer in fullscreen mode
        [can/does](https://github.com/TigerVNC/tigervnc/issues/1150)
        interact weirdly with screensavers. When xscreensaver locks
        the screen, xvncviewer apparently keeps its own window atop
        the screensaver's, thus the locking can't be noticed; the
        keyboard appears dead at that point. But simply clicking into
        the window shown by the VNC client revives the keyboard focus.
    
    If you're on OS X, replace points 1 and 3 with appropriate alternatives.

* Copy over passwd file from client side:

        scp .vncclient-passwords/coworking-passwd root@$server:/opt/chj/chjize/tmp/passwd

* Log in freshly as root to pick up the `PATH` change from `moduser` above.

        ssh root@$server

* If wanting to use Guix, which implies updating the system to Debian sid (bullseye):

        time chjize guix

* For co-working (on a 2 core, 2 GB RAM instance on Exoscale,
  this takes 1m15s)

        time chjize coworking

* On the client side, run `tunnel-tmp` and then `vnc-coworking`.

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

