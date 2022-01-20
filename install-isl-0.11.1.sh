#!/bin/bash

# Install isl on OS X Leopard / PowerPC.

package=isl
version=0.11.1

set -e -x -o pipefail
PATH="/opt/portable-curl/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://ssl.pepas.com/leopardsh}

if ! test -e /opt/gmp-4.3.2; then
    leopard.sh gmp-4.3.2
fi

echo -n -e "\033]0;Installing $package-$version\007"

binpkg=$package-$version.$(leopard.sh --os.cpu).tar.gz
if curl -sSfI $LEOPARDSH_MIRROR/$binpkg >/dev/null 2>&1 && test -z "$LEOPARDSH_FORCE_BUILD"; then
    cd /opt
    curl -#f $LEOPARDSH_MIRROR/$binpkg | gunzip | tar x
else
    srcmirror=https://gcc.gnu.org/pub/gcc/infrastructure
    tarball=$package-$version.tar.bz2

    if ! test -e ~/Downloads/$tarball; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    cd /tmp
    rm -rf $package-$version
    tar xjf ~/Downloads/$tarball
    cd $package-$version
    ./configure --prefix=/opt/$package-$version \
        --with-gmp-prefix=/opt/gmp-4.3.2
    make V=1

    if test -n "$LEOPARDSH_MAKE_CHECK"; then
        make check
    fi

    make install
fi
