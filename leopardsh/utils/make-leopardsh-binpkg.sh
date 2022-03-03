#!/bin/bash

if test -z "$1" ; then
    echo "Error: make package for which pkgspec?" >&2
    echo "e.g. $0 gzip-1.11" >&2
    exit 1
fi

set -e -x

pkgspec=$1
binpkg=$pkgspec.$(leopard.sh --os.cpu).tar.gz

LEOPARDSH_BINPKG_PATH=${LEOPARDSH_BINPKG_PATH:-~/Desktop/leopard.sh/binpkgs}
mkdir -p $LEOPARDSH_BINPKG_PATH

cd /opt
tmpfile=$(mktemp /tmp/binpkg.XXXX)
chmod 644 $tmpfile
tar c $pkgspec | gzip -9 > $tmpfile
mv $tmpfile $LEOPARDSH_BINPKG_PATH/$binpkg
