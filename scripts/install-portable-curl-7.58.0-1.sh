#!/bin/bash

# Install portable curl (with ssl support) from tigerbrew.

set -e -x -o pipefail

package=portable-curl
version="7.58.0-1"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://ssl.pepas.com/leopardsh}

tarball=$package-$version.tiger_g3.bottle.tar.gz

if ! test -e ~/Downloads/$tarball; then
    cd ~/Downloads
    curl -#fLOk $LEOPARDSH_MIRROR/$tarball
fi

cd /tmp
rm -rf $package
tar xzf ~/Downloads/$tarball
cd /opt
mv /tmp/$package/$version /opt/$package-$version
rmdir /tmp/$package
ln -sf /opt/$package-$version /opt/$package
