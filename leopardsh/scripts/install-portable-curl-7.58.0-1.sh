#!/bin/bash

# Install portable curl (with ssl support) from tigerbrew.

set -e -x -o pipefail

package=portable-curl
version="7.58.0-1"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://ssl.pepas.com/leopardsh}

pkgspec=$package-$version

tarball=$package-$version.tiger_g3.bottle.tar.gz

if ! test -e ~/Downloads/$tarball ; then
    cd ~/Downloads
    curl -#fLOk $LEOPARDSH_MIRROR/$tarball
fi

test "$(md5 ~/Downloads/$tarball | awk '{print $NF}')" = 678fcb1b24c4835695b3f66177886eba

rm -rf /tmp/$package
cd /tmp
tar xzf ~/Downloads/$tarball

rm -rf /opt/$package /opt/$pkgspec
mv /tmp/$package/$version /opt/$pkgspec
rmdir /tmp/$package
ln -sf /opt/$pkgspec /opt/$package
