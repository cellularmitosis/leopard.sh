#!/bin/bash

# Install sqlite on OS X Leopard / PowerPC.

package=sqlite
version=3.37.2

set -e -x -o pipefail
PATH="/opt/portable-curl/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://ssl.pepas.com/leopardsh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

if ! test -e /opt/readline-8.1.2$ppc64 ; then
    leopard.sh readline-8.1.2$ppc64
fi

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --os.cpu))\007"

binpkg=$pkgspec.$(leopard.sh --os.cpu).tar.gz
if curl -sSfI $LEOPARDSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$LEOPARDSH_FORCE_BUILD" ; then
    cd /opt
    curl -#f $LEOPARDSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else
    srcmirror=https://www.sqlite.org/2022
    tarball=$package-autoconf-3370200.tar.gz

    if ! test -e ~/Downloads/$tarball ; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    cd /tmp
    rm -rf sqlite-autoconf-3370200
    tar xzf ~/Downloads/$tarball
    cd sqlite-autoconf-3370200

    cat /opt/leopard.sh/share/leopard.sh/config.cache/leopard.cache > config.cache

    CPPFLAGS=-I/opt/readline-8.1.2$ppc64/include \
        LDFLAGS=-L/opt/readline-8.1.2$ppc64/lib \
        ./configure -C --prefix=/opt/$pkgspec \
            --disable-dependency-tracking \
            --enable-threadsafe \
            --enable-readline

    make $(leopard.sh -j)

    if test -n "$LEOPARDSH_RUN_TESTS" ; then
        make check
    fi

    make install

    leopard.sh --linker-check $pkgspec
    leopard.sh --arch-check $pkgspec $ppc64

    if test -e config.cache ; then
        mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
        gzip config.cache
        mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
    fi
fi

if test -e /opt/$pkgspec/bin ; then
    ln -sf /opt/$pkgspec/bin/* /usr/local/bin/
fi

if test -e /opt/$pkgspec/sbin ; then
    ln -sf /opt/$pkgspec/sbin/* /usr/local/sbin/
fi

# Note: --disable-dependency-tracking speeds up one-time builds.
