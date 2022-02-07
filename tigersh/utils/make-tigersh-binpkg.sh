#!/bin/bash

set -e -x

pkgspec=$1
cd /opt
binpkg=$pkgspec.$(tiger.sh --os.cpu).tar.gz
TIGERSH_BINPKG_PATH=${TIGERSH_BINPKG_PATH:-~/Desktop/tiger.sh/binpkgs}
mkdir -p $TIGERSH_BINPKG_PATH
tar czf /tmp/$binpkg $pkgspec
mv /tmp/$binpkg $TIGERSH_BINPKG_PATH/
