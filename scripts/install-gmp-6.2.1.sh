#!/bin/bash

# Install gmp on Tiger / PowerPC.

package=gmp
version=6.2.1

set -e -x -o pipefail
PATH="/opt/portable-curl/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://ssl.pepas.com/leopardsh}

if ! which -s gcc-4.2; then
    leopard.sh gcc-4.2
fi

if ! which -s xz; then
    leopard.sh xz-5.2.5
fi

echo -n -e "\033]0;Installing $package-$version\007"

binpkg=$package-$version.$(leopard.sh --os.cpu).tar.gz
if curl -sSfI $LEOPARDSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$LEOPARDSH_FORCE_BUILD"; then
    cd /opt
    curl -#f $LEOPARDSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else
    srcmirror=https://ftp.gnu.org/gnu/$package
    tarball=$package-$version.tar.xz

    if ! test -e ~/Downloads/$tarball; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    cd /tmp
    rm -rf $package-$version
    cat ~/Downloads/$tarball | unxz | tar x
    cd $package-$version
    CC=gcc-4.2 CXX=g++-4.2 ./configure -C \
        --prefix=/opt/$package-$version \
        --enable-cxx
    make

    if test -n "$LEOPARDSH_MAKE_CHECK"; then
        make check
    fi

    make install
fi

# Note: /usr/bin/gcc (4.0.1) fails with:
#   ld: duplicate symbol ___gmpz_abs in .libs/compat.o and .libs/assert.o
# So we use gcc-4.2 instead.
# Thanks to https://gmplib.org/list-archives/gmp-bugs/2010-January/001837.html
