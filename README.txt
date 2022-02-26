+-----------------------------+
| `leopard.sh` and `tiger.sh` |
+-----------------------------+

Package managers for PowerPC Macs running OS X Leopard (10.5) and Tiger (10.4),
written in Bash!

See also leopardsh/README.md and tigersh/README.md.


In a nutshell:
--------------

    $ curl -O http://leopard.sh/leopard.sh
    $ chmod +x leopard.sh
    $ ./leopard.sh quake.app-1.1
    $ open "/Applications/GLQuake 1.1"


Binary package support:
-----------------------

I build pre-compiled binary packages optimized for the following platforms:

+---------+----+----+-----+-------+-------+
|         | G3 | G4 | G4e | G5/32 | G5/64 |
|---------|----|----|-----|-------|-------|
| Leopard |    |    |  X  |   X   |   X   |
| Tiger   |  X |  X |  X  |   X   |   X   |
+---------+----+----+-----+-------+-------+

The above processors can be understood as the following gcc flags:

- G3:    `-mcpu=750`
- G4:    `-mcpu=7400`
- G4e:   `-mcpu=7450`
- G5/32: `-mcpu=970 -m32`
- G5/64: `-mcpu=970 -m64`


Installation:
-------------

On your Mac, open up Terminal.app.

Download the `leopard.sh` Bash script:

    $ curl -O http://leopard.sh/leopard.sh

or, for Tiger users:

    $ curl -O http://leopard.sh/tiger.sh

Now make it executable:

    $ chmod +x leopard.sh

Now run it:

    $ ./leopard.sh

During the first run, some setup will be performed, e.g. creating /opt,
downloading a few dependencies, etc.  You'll be prompted for your password,
because a few of these commands need root access.

Also, you'll be prompted to visit https://leopard.sh/md5 to verify that the
script wasn't tampered with during download.  Because the version of Safari
which shipped with Leopard and Tiger doesn't support modern SSL, this step has
to be performed on either a modern PC or on your smartphone.

You'll need to move `leopard.sh` to somewhere in your $PATH.  This is because
some of the package installer scripts need to call `leopard.sh` recursively.

You can either move it to a system-wide location, like `/usr/local/bin`:

    $ mv leopard.sh /usr/local/bin/

or if you know how to edit your `$PATH`, perhaps somewhere like `~/bin`.


List the available packages:
----------------------------

Fetch the list of the available packages:

    $ ./leopard.sh
    Available packages:
    adium.app-1.3.10
    clisp-2.39.20210628
    coreutils-9.0
    gcc-4.9.4
    gettext-0.20
    gmp-4.3.2
    gzip-1.11
    handbrake.app-0.9.1
    ...

These names, e.g. `gzip-1.11` are called "pkgspecs".

You'll also notice that there are two kinds of pkgspecs supported:
- Unix software, e.g. gzip-1.11
- Mac applications, e.g. adium.app-1.3.10

Note that the pkgspecs are printed to stdout, while the "Available packages:"
header is printed to stderr.  This means we can pipe `leopard.sh` into `grep`:

    $ leopard.sh | grep gzip
    Available packages:
    gzip-1.11

We could also use `grep` to list just the Mac applications:

    $ leopard.sh | grep .app
    Available packages:
    adium.app-1.3.10
    chicken.app-2.2b2
    clozure-cl.app-1.4
    handbrake.app-0.9.1
    interwebppc.app-rr1
    quake.app-1.1
    textwrangler.app-3.1
    vlc.app-0.9.10
    xbench.app-1.3
    ...

The Unix geeks will note that technically we should grep for '\.app', not .app.


Install a package:
------------------

To install a package, call `leopard.sh` with a pkgspec:

    $ leopard.sh gzip-1.11

Note: currently, you have to use the full pkgspec, i.e. you can't do something
like "leopard.sh gzip".  I'll implement some sort of pkgspec aliases soon, but
in the mean time you could use a subshell as a work-around:

    $ leopard.sh $(leopard.sh | grep gzip)

The above command will fetch and run
http://leopard.sh/leopardsh/scripts/install-gzip-1.11.sh.

That script will look for a pre-compiled binary package (a "binpkg") which
matches your CPU type, e.g. a Mac with a G5 would try to fetch
https://leopard.sh/leopardsh/binpkgs/gzip-1.11.leopard.g5.tar.gz and unpack it
into /opt/gzip-1.11, and create symlinks in /usr/local/bin.

If for some reason a binpkg is unavailable, the script will instead attempt to
compile gzip-1.11 from source.  (However, I currently build binpkgs for every
supported OS / CPU combo, so I'm the only one who will ever see this step).

Some pkgspecs depend on other pkgspecs, i.e.
https://leopard.sh/leopardsh/scripts/install-gcc-4.9.4.sh

In that case, the script will call `leopard.sh` to install each of its
dependencies, and so on, recursively.


Remove a package:
-----------------

To remove a package, first clean up its symlinks from `/usr/local/bin`:

    $ leopard.sh --unlink gzip-1.11

and then delete it from `/opt`:

    $ rm -rf /opt/gzip-1.11

That's right: you remove packages from `/opt` manually.  Note that `leopard.sh`
does not maintain any sort of database or state tracking about what's currently
installed (it simply checks if /opt/foo-1.0 exists), so in general you are
free to muck with /opt in any way you see fit.  That is, `leopard.sh` does not
*own* /opt, it is a *citizen* of /opt.

If you had previously unlinked a package but hadn't actually deleted it, and
now you'd like to re-link it, here's how to do that:

    $ rm -rf /opt/gzip-1.11
    $ leopard.sh gzip-1.11

No, I'm not kidding :)  Of course you could also just manually run:

    $ ln -s /opt/gzip-1.11/bin/* /usr/local/bin/


Project goals:
--------------

- Full binary package availability.

Every pkgspec should have a pre-compiled binary package available for every
OS / CPU combo.  Users should never wait on compilation.

- Simplicity / hackability / conceptual flatness.

The problem with most package managers is that they have a very steep learning
curve for contributing / hacking.

`leopard.sh` and `tiger.sh` will take the opposite approach: the installation
of a package shall be encompassed entirely by two Bash scripts:
- the orchestrator script: `leopard.sh` or `tiger.sh`
- the package-specific script: e.g. `install-gzip-1.11.sh`

`leopard.sh` and `tiger.sh` are spritual brethren to the 'Linux From Scratch'
project (see https://www.linuxfromscratch.org/).

Would you like to hack on some of the installer scripts yourself?  It is as
simple as:

    $ cd
    $ curl -L https://github.com/cellularmitosis/leopard.sh/archive/refs/heads/main.tar.gz | gunzip | tar x
    $ export LEOPARDSH_MIRROR=file://$HOME/leopard.sh-main/leopardsh
    $ # or, for tiger:
    $ export TIGERSH_MIRROR=file://$HOME/leopard.sh-main/tigersh

Bam, you're now running entirely from your self-contained copy of the project.

In fact, as long as you drop any needed source tarballs into `~/Downloads`
before running `leopard.sh`, you're now also completely offline-capable.


Non-goals:
----------

- Supporting Intel Macs ;p


Possible future work:
---------------------

### 10.3 / 10.2

If I really get serious with this rabbit-hole, I might look at seeing what will
port to Panther (10.3) and even Jaguar (10.2).

In a [blog post](https://gist.github.com/cellularmitosis/c56bb91d0b1ad0cd785ccd302abbba7c)
I looked at data from [Everymac.com](https://everymac.com/systems/by_capability/maximum-macos-supported.html)
to see which Macs are stuck on 10.3 and 10.2:

There are 9 Macs stuck on 10.3:

    ['iBook', 'G3/300_(Original/Clamshell)', 'X_10.3.9']
    ['iBook_G3/366_SE_(Original/Clamshell)', 'X', '10.3.9']
    ['iMac_G3_233_Original_-_Bondi_(Rev._A_&_B)', 'X_10.3.9']
    ['iMac_G3_266_(Fruit', 'Colors)', 'X_10.3.9']
    ['iMac_G3_333_(Fruit_Colors)', 'X_10.3.9']
    ['iMac_G3_350_(Slot', 'Loading_-_Blueberry)', 'X_10.3.9']
    ['iMac_G3_350_(Summer', '2000_-_Indigo)', 'X_10.3.9']
    ['PowerBook_G3_333_(Bronze_KB/Lombard)', 'X_10.3.9']
    ['PowerBook', 'G3_400_(Bronze_KB/Lombard)', 'X_10.3.9']

There are 19 Macs stuck on 10.2:

    ['Mac_Server_G3_233_Minitower', 'X', '10.2.8']
    ['Mac_Server_G3_266_Minitower', 'X_10.2.8']
    ['Mac_Server_G3_300_Minitower', 'X_10.2.8']
    ['Mac_Server_G3_333_Minitower', 'X_10.2.8']
    ['PowerBook_G3_233_', '(Wallstreet)', 'X_10.2.8']
    ['PowerBook_G3_250_(Wallstreet)', 'X_10.2.8']
    ['PowerBook', 'G3_292_(Wallstreet)', 'X_10.2.8']
    ['PowerBook_G3_233_(PDQ_-_Late_1998)', 'X_10.2.8']
    ['PowerBook_G3_266_(PDQ_-_Late_1998)', 'X_10.2.8']
    ['PowerBook_G3_300_(PDQ_-_Late', '1998)', 'X_10.2.8']
    ['Power', 'Macintosh_G3_233_Desktop', 'X_10.2.8']
    ['Power_Macintosh_G3_233_Minitower', 'X_10.2.8']
    ['Power_Macintosh_G3_266_Desktop', 'X_10.2.8']
    ['Power_Macintosh_G3_266_Minitower', 'X_10.2.8']
    ['Power_Macintosh_G3_300_Desktop', 'X_10.2.8']
    ['Power_Macintosh_G3_300', 'Minitower', 'X_10.2.8']
    ['Power_Macintosh_G3_333_Minitower', 'X_10.2.8']
    ['Power', 'Macintosh_G3_233_All-in-One', 'X_10.2.8']
    ['Power_Macintosh_G3_266_All-in-One', 'X', '10.2.8']


Other options:
--------------

If `leopard.sh` and `tiger.sh` aren't for you, checkout these other package managers:
- MacPorts: https://www.macports.org/
- Tigerbrew: https://github.com/mistydemeo/tigerbrew
- Fink: https://www.finkproject.org/ (looks like they only support 10.6 and up these days)


Useful links for OS X PowerPC users:
------------------------------------

- 'Last versions of applications for Mac OS X on PowerPC' http://matejhorvat.si/en/mac/osxppcsw/
- 'The Tiger Thread' (Mac OS X 10.4' https://forums.macrumors.com/threads/the-tiger-thread-mac-os-x-10-4.2134451/
- 'The Leopard Thread' https://forums.macrumors.com/threads/the-leopard-thread.2120703/
