#!/bin/bash

# (re)build everything, wiping in between each package build.

set -e -x

osversion=$(sw_vers -productVersion | awk '{print $NF}')
if test "${osversion:0:4}" = "10.4" ; then
    pkgmgr="tiger.sh"
    mirror=$TIGERSH_MIRROR
elif test "${osversion:0:4}" = "10.5" ; then
    pkgmgr="leopard.sh"
    mirror=$LEOPARDSH_MIRROR
fi
test -n "$pkgmgr"

$pkgmgr --setup

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
rm -f build-order.txt build-order.ppc64.txt

/opt/portable-curl/bin/curl -sSfLO $mirror/build-order.txt

if test -n "%is_g5" ; then
    /opt/portable-curl/bin/curl -sSfLO $mirror/build-order.ppc64.txt
    cat build-order.ppc64.txt >> build-order.txt
fi

rm -f ~/Desktop/binpkgs/*

for pkgspec in $(cat /tmp/build-order.txt) ; do
    rm -rf /usr/local/bin/*
    rm -rf /usr/local/sbin/*
    if test -e /opt/local ; then
        echo "Error: refusing to delete /opt/local." >&2
        exit 1
    fi
    rm -rf /opt/*
    if test "$pkgmgr" = "leopard.sh" ; then
        time LEOPARDSH_FORCE_BUILD_PKGSPEC=$pkgspec $pkgmgr $pkgspec
    elif test "$pkgmgr" = "tiger.sh" ; then
        time TIGERSH_FORCE_BUILD_PKGSPEC=$pkgspec $pkgmgr $pkgspec
    else
        echo "Error: unreachable" >&2
        exit 1
    fi
    ~/bin/make-binpkg.sh $pkgspec
done
