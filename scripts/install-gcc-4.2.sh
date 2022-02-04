#!/bin/bash

# Install gcc 4.2 from tigerbrew.

package=gcc
version=4.2

set -e -x -o pipefail
PATH="/opt/portable-curl/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://ssl.pepas.com/leopardsh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

mirror=https://archive.org/download/tigerbrew
tarball=gcc-42-5553-darwin8-all.tar.gz

if ! test -e ~/Downloads/$tarball ; then
    cd ~/Downloads
    /opt/portable-curl/bin/curl -#fLO $mirror/$tarball
fi

cd /
sudo tar xzf ~/Downloads/$tarball
