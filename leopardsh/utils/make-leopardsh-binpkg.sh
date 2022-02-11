#!/bin/bash

set -e -x

pkgspec=$1
binpkg=$pkgspec.$(leopard.sh --os.cpu).tar.gz

LEOPARDSH_BINPKG_PATH=${LEOPARDSH_BINPKG_PATH:-~/Desktop/leopardsh/binpkgs}
mkdir -p $LEOPARDSH_BINPKG_PATH

cd /opt
tmpfile=$(mktemp /tmp/binpkg.XXXX)
tar czf $tmpfile $pkgspec
mv $tmpfile $LEOPARDSH_BINPKG_PATH/$binpkg
