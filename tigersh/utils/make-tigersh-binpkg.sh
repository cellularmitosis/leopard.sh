#!/bin/bash

if test -z "$1" ; then
    echo "Error: make package for which pkgspec?" >&2
    echo "e.g. $0 gzip-1.11" >&2
    exit 1
fi

set -e -x

pkgspec=$1
binpkg=$pkgspec.$(tiger.sh --os.cpu).tar.gz

TIGERSH_BINPKG_PATH=${TIGERSH_BINPKG_PATH:-~/Desktop/leopard.sh/binpkgs}
mkdir -p $TIGERSH_BINPKG_PATH

cd /opt
tmpfile=$(mktemp /tmp/binpkg.XXXX)
chmod 644 $tmpfile
tar c $pkgspec | gzip -9 > $tmpfile
mv $tmpfile $TIGERSH_BINPKG_PATH/$binpkg
