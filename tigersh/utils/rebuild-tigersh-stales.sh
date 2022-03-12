#!/bin/bash

# (re)build everything which is out of date.

set -e

if test "$1" = "--dry-run" -o "$1" = "-d" ; then
    shift 1
    dry_run=1
fi

if test "$1" = "--force" -o "$1" = "-f" ; then
    shift 1
    force=1
fi

cpu=$(sysctl hw.cpusubtype | awk '{print $NF}')
if test "$cpu" = "9" ; then
    is_g3=1
elif test "$cpu" = "10" ; then
    is_g4=1
elif test "$cpu" = "11" ; then
    is_g4e=1
elif test "$cpu" = "100" ; then
    is_g5=1
else
    echo "Error: unsupported CPU type." >&2
    exit 1
fi

cd /tmp
rm -f build-order.txt build-order.ppc64.txt to-build.txt

tiger.sh --setup
export PATH="/opt/tigersh-deps-0.1/bin:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"


if test -n "$1" ; then
    # if the user specifies a pkgspec, just rebuild that one.
    echo "$1" > /tmp/to-build.txt
else
    curl -sSfLO $TIGERSH_MIRROR/build-order.txt

    if test -n "$is_g5" ; then
        curl -sSfLO $TIGERSH_MIRROR/build-order.ppc64.txt
        cat build-order.ppc64.txt >> build-order.txt
    fi

    # one pass to detect stale packages.
    for pkgspec in $(cat /tmp/build-order.txt) ; do
        echo -n "." >&2
        should_build=0
        binpkg=$pkgspec.$(tiger.sh --os.cpu).tar.gz
        if ! test -e ~/Desktop/leopard.sh/binpkgs/$binpkg ; then
            should_build=1
        else
            curl -RsSfLO $TIGERSH_MIRROR/scripts/install-$pkgspec.sh
            binpkg_mtime=$(stat -L -f '%m' ~/Desktop/leopard.sh/binpkgs/$binpkg)
            script_mtime=$(stat -L -f '%m' install-$pkgspec.sh)
            if test "$binpkg_mtime" -lt "$script_mtime" ; then
                should_build=1
            fi
        fi

        if test "$should_build" = "1" ; then
            echo $pkgspec >> /tmp/to-build.txt
        fi
    done
    echo >&2
fi

if test -z "$force" && ! test -e /tmp/to-build.txt ; then
    echo "Nothing to build." >&2
    exit 0
fi

if test -n "$dry_run" ; then
    echo "Would build:" >&2
    cat /tmp/to-build.txt
    exit 0
fi

# another pass to wipe.
for pkgspec in $(cat /tmp/to-build.txt) ; do
    binpkg=$pkgspec.$(tiger.sh --os.cpu).tar.gz
    rm -f ~/Desktop/leopard.sh/binpkgs/$binpkg
done

set -x

# and another pass to build.
for pkgspec in $(cat /tmp/to-build.txt) ; do
    mv /usr/local/bin/tiger.sh /opt/tigersh-deps-0.1 /tmp/

    rm -rf /usr/local/bin/*
    rm -rf /usr/local/sbin/*
    rm -rf /usr/local/share/man/*
    if test -e /opt/local ; then
        echo "Error: refusing to delete /opt/local." >&2
        exit 1
    fi
    rm -rf /opt/*

    mv /tmp/tiger.sh /usr/local/bin/
    mv /tmp/tigersh-deps-0.1 /opt/

    binpkg=$pkgspec.$(tiger.sh --os.cpu).tar.gz
    rm -f ~/Desktop/leopard.sh/binpkgs/$binpkg
    time TIGERSH_FORCE_BUILD_PKGSPEC=$pkgspec tiger.sh $pkgspec
    ~/bin/make-tigersh-binpkg.sh $pkgspec
done
