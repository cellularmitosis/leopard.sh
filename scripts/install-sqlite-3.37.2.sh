#!/bin/bash

# Install sqlite on OS X Leopard / PowerPC.

package=sqlite
version=3.37.2

set -e -x -o pipefail
PATH="/opt/portable-curl/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://ssl.pepas.com/leopardsh}

if ! test -e /opt/readline-8.1.2; then
    leopard.sh readline-8.1.2
fi

echo -n -e "\033]0;Installing $package-$version\007"

binpkg=$pkgspec.$(leopard.sh --os.cpu).tar.gz
if curl -sSfI $LEOPARDSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$LEOPARDSH_FORCE_BUILD"; then
    cd /opt
    curl -#f $LEOPARDSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else
    srcmirror=https://www.sqlite.org/2022
    tarball=$package-autoconf-3370200.tar.gz

    if ! test -e ~/Downloads/$tarball; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    cd /tmp
    rm -rf sqlite-autoconf-3370200
    tar xzf ~/Downloads/$tarball
    cd sqlite-autoconf-3370200
    CPPFLAGS=-I/opt/readline-8.1.2/include \
        LDFLAGS=-L/opt/readline-8.1.2/lib \
        ./configure -C --prefix=/opt/$package-$version \
            --disable-dependency-tracking \
            --enable-threadsafe \
            --enable-readline
    make $(leopard.sh -j)

    if test -n "$LEOPARDSH_RUN_TESTS"; then
        make check
    fi

    make install
fi

ln -sf /opt/$package-$version/bin/* /usr/local/bin/

# Note: --disable-dependency-tracking speeds up one-time builds.
