#!/bin/bash

# Install portable curl (with ssl support) from tigerbrew.

set -e -x

package=portable-curl
version="7.58.0-1"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://ssl.pepas.com/tigersh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

pkgspec=$package-$version

tarball=$package-$version.tiger_g3.bottle.tar.gz

if ! test -e ~/Downloads/$tarball ; then
    cd ~/Downloads
    curl -#fLOk $TIGERSH_MIRROR/$tarball
fi

rm -rf /tmp/$package
cd /tmp
tar xzf ~/Downloads/$tarball

rm -rf /opt/$package /opt/$pkgspec
mv /tmp/$package/$version /opt/$pkgspec
rmdir /tmp/$package
ln -sf /opt/$pkgspec /opt/$package
