#!/bin/bash

set -e -x

pkg=$1
cd /opt
binpkg=$pkg.$(leopard.sh --os.cpu).tar.gz
LEOPARDSH_BINPKG_PATH=${LEOPARDSH_BINPKG_PATH:-~/Desktop/leopard.sh/binpkgs}
mkdir -p $LEOPARDSH_BINPKG_PATH
tar czf /tmp/$binpkg $pkg
mv /tmp/$binpkg $LEOPARDSH_BINPKG_PATH/
