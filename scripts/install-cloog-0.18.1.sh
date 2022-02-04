#!/bin/bash

# Install cloog on OS X Leopard / PowerPC.

package=cloog
version=0.18.1

set -e -x -o pipefail
PATH="/opt/portable-curl/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://ssl.pepas.com/leopardsh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

if ! test -e /opt/gmp-4.3.2 ; then
    leopard.sh gmp-4.3.2
fi

if ! test -e /opt/isl-0.11.1 ; then
    leopard.sh isl-0.11.1
fi

echo -n -e "\033]0;Installing $package-$version\007"

binpkg=$pkgspec.$(leopard.sh --os.cpu).tar.gz
if curl -sSfI $LEOPARDSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$LEOPARDSH_FORCE_BUILD" ; then
    cd /opt
    curl -#f $LEOPARDSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else
    srcmirror=https://gcc.gnu.org/pub/gcc/infrastructure
    tarball=$package-$version.tar.gz

    if ! test -e ~/Downloads/$tarball ; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    cd /tmp
    rm -rf $package-$version
    tar xzf ~/Downloads/$tarball
    cd $package-$version
    ./configure -C --prefix=/opt/$pkgspec \
        --with-isl-prefix=/opt/isl-0.11.1 \
        --with-gmp-prefix=/opt/gmp-4.3.2
    make $(leopard.sh -j)

    if test -n "$LEOPARDSH_RUN_TESTS" ; then
        # FIXME some tests are failing
        make check
    fi

    make install
fi
