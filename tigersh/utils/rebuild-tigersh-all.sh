#!/bin/bash

# (re)build everything, wiping in between each package build.

set -e -x

tiger.sh --setup

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

/opt/portable-curl/bin/curl -sSfLO $TIGERSH_MIRROR/build-order.txt

if test -n "%is_g5" ; then
    /opt/portable-curl/bin/curl -sSfLO $TIGERSH_MIRROR/build-order.ppc64.txt
    cat build-order.ppc64.txt >> build-order.txt
fi

rm -f ~/Desktop/tigersh/binpkgs/*

for pkgspec in $(cat /tmp/build-order.txt) ; do
    rm -rf /usr/local/bin/*
    rm -rf /usr/local/sbin/*
    if test -f /opt/local ; then
        echo "Error: refusing to delete /opt/local." >&2
        exit 1
    fi
    rm -rf /opt/*
    time TIGERSH_FORCE_BUILD_PKGSPEC=$pkgspec tiger.sh $pkgspec
    ~/Desktop/tigersh/utils/make-tigersh-binpkg.sh $pkgspec
done
