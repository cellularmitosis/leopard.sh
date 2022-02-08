#!/bin/bash

# Install gcc 7.3.0 from tigerbrew.

package=gcc
version=7.3.0

set -e -x -o pipefail
PATH="/opt/portable-curl/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://ssl.pepas.com/leopardsh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

mirror=https://archive.org/download/tigerbrew
tarball=$package-$version.tiger_g3.bottle.tar.gz

if ! test -e ~/Downloads/$tarball ; then
    cd ~/Downloads
    /opt/portable-curl/bin/curl -fLO $mirror/$tarball
fi

cd /tmp
rm -rf $package
tar xzf ~/Downloads/$tarball
mv $package/$version /opt/$pkgspec
rmdir $package

if test -e /opt/$pkgspec/bin ; then
    ln -sf /opt/$pkgspec/bin/* /usr/local/bin/
fi

if test -e /opt/$pkgspec/sbin ; then
    ln -sf /opt/$pkgspec/sbin/* /usr/local/sbin/
fi