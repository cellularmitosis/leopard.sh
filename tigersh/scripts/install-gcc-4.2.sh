#!/bin/bash

# Install gcc 4.2 from tigerbrew.

package=gcc
version=4.2

set -e -x
PATH="/opt/portable-curl/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://ssl.pepas.com/tigersh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

if type -a gcc-4.2 >/dev/null 2>&1 ; then
    echo "gcc-4.2 is already installed." >&2
    exit 0
fi

mirror=https://archive.org/download/tigerbrew
tarball=gcc-42-5553-darwin8-all.tar.gz

if ! test -e ~/Downloads/$tarball ; then
    cd ~/Downloads
    /opt/portable-curl/bin/curl -#fLO $mirror/$tarball
fi

test "$(md5 ~/Downloads/$tarball | awk '{print $NF}')" = xxxxxxxzxxxxxxxxxxzxxxxxxxxxxzx

cd /
sudo tar xzf ~/Downloads/$tarball
