#!/bin/bash

set -e -x

pkgspec=$1
binpkg=$pkgspec.$(tiger.sh --os.cpu).tar.gz

TIGERSH_BINPKG_PATH=${TIGERSH_BINPKG_PATH:-~/Desktop/tigersh/binpkgs}
mkdir -p $TIGERSH_BINPKG_PATH

cd /opt
tmpfile=$(mktemp /tmp/binpkg.XXXX)
tar c $pkgspec | gzip -9 > $tmpfile
mv $tmpfile $TIGERSH_BINPKG_PATH/$binpkg
