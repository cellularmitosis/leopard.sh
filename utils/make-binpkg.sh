#!/bin/bash

if test -z "$1" ; then
    echo "Error: make package for which pkgspec?" >&2
    echo "e.g. $0 gzip-1.11" >&2
    exit 1
fi

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

pkgspec=$1
binpkg=$pkgspec.$($pkgmgr --os.cpu).tar.gz

LEOPARDSH_BINPKG_PATH=${LEOPARDSH_BINPKG_PATH:-~/Desktop/binpkgs}
TIGERSH_BINPKG_PATH=${TIGERSH_BINPKG_PATH:-~/Desktop/binpkgs}
if test "$pkgmgr" = "leopard.sh" ; then
    binpkg_path=$LEOPARDSH_BINPKG_PATH
elif test "$pkgmgr" = "tiger.sh" ; then
    binpkg_path=$TIGERSH_BINPKG_PATH
else
    echo "Error: unreachable" >&2
    exit 1
fi
mkdir -p $binpkg_path

cd /opt
tmpfile=$(mktemp /tmp/binpkg.XXXX)
chmod 644 $tmpfile
tar c $pkgspec | gzip -9 > $tmpfile
mv $tmpfile $binpkg_path/$binpkg
