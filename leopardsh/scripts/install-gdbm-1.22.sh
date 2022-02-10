#!/bin/bash

# Install gdbm on OS X Leopard / PowerPC.

package=gdbm
version=1.22

set -e -x -o pipefail
PATH="/opt/portable-curl/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://ssl.pepas.com/leopardsh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

if ! test -e /opt/libiconv-1.16$ppc64 ; then
    leopard.sh libiconv-1.16$ppc64
fi

if ! test -e /opt/gettext-0.21$ppc64 ; then
    leopard.sh gettext-0.21$ppc64
fi

if ! test -e /opt/readline-8.1.2$ppc64 ; then
    leopard.sh readline-8.1.2$ppc64
fi

echo -n -e "\033]0;leopard.sh $pkgspec ($(hostname -s))\007"

binpkg=$pkgspec.$(leopard.sh --os.cpu).tar.gz
if curl -sSfI $LEOPARDSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$LEOPARDSH_FORCE_BUILD" ; then
    cd /opt
    curl -#f $LEOPARDSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else
    srcmirror=https://ftp.gnu.org/gnu/$package
    tarball=$package-$version.tar.gz

    if ! test -e ~/Downloads/$tarball ; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    cd /tmp
    rm -rf $package-$version
    tar xzf ~/Downloads/$tarball
    cd $package-$version

    cat /opt/leopard.sh/share/leopard.sh/config.cache/leopard.cache > config.cache

    CPPFLAGS=-I/opt/readline-8.1.2$ppc64/include \
    LDFLAGS=-L/opt/readline-8.1.2$ppc64/lib \
        ./configure -C --prefix=/opt/$pkgspec \
            --with-libiconv-prefix=/opt/libiconv-1.16$ppc64 \
            --with-libintl-prefix=/opt/gettext-0.21$ppc64 \
            --with-readline

    make $(leopard.sh -j)

    if test -n "$LEOPARDSH_RUN_TESTS" ; then
        make check
    fi

    make install

    leopard.sh --arch-check $pkgspec

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

# input-rl.c: In function 'instream_readline_history_get':
# input-rl.c:194: error: subscripted value is neither array nor pointer
