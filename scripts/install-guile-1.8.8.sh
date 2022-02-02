#!/bin/bash

# Install guile on OS X Leopard / PowerPC.

package=guile
version=1.8.8

set -e -x -o pipefail
PATH="/opt/portable-curl/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://ssl.pepas.com/leopardsh}

if ! test -e /opt/gmp-4.3.2; then
    leopard.sh gmp-4.3.2
fi

if ! test -e /opt/libiconv-1.16; then
    leopard.sh libiconv-1.16
fi

echo -n -e "\033]0;Installing $package-$version\007"

binpkg=$package-$version.$(leopard.sh --os.cpu).tar.gz
if curl -sSfI $LEOPARDSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$LEOPARDSH_FORCE_BUILD"; then
    cd /opt
    curl -#f $LEOPARDSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else
    srcmirror=https://ftp.gnu.org/gnu/$package
    tarball=$package-$version.tar.gz

    if ! test -e ~/Downloads/$tarball; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    cd /tmp
    rm -rf $package-$version
    tar xzf ~/Downloads/$tarball
    cd $package-$version
    # Note: there is on --with-gmp option, so we use env vars.
    CPPFLAGS=-I/opt/gmp-4.3.2/include \
    LDFLAGS=-L/opt/gmp-4.3.2/lib \
    LIBS=-lgmp \
        ./configure -C --prefix=/opt/$package-$version \
            --with-libiconv-prefix=/opt/libiconv-1.16 \
            --with-threads
    make $(leopard.sh -j)

    if test -n "$LEOPARDSH_MAKE_CHECK"; then
        make check
    fi

    make install
fi

ln -sf /opt/$package-$version/bin/* /usr/local/bin/
