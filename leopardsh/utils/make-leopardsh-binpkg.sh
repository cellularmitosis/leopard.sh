#!/bin/bash

set -e -x

pkgspec=$1
cd /opt
binpkg=$pkgspec.$(leopard.sh --os.cpu).tar.gz
LEOPARDSH_BINPKG_PATH=${LEOPARDSH_BINPKG_PATH:-~/Desktop/leopard.sh/binpkgs}
mkdir -p $LEOPARDSH_BINPKG_PATH
tar czf /tmp/$binpkg $pkgspec
mv /tmp/$binpkg $LEOPARDSH_BINPKG_PATH/
