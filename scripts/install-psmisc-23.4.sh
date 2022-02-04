#!/bin/bash

# Install psmisc on OS X Leopard / PowerPC.

package=psmisc
version=23.4

set -e -x -o pipefail
PATH="/opt/portable-curl/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://ssl.pepas.com/leopardsh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

if ! which -s xz ; then
    leopard.sh xz-5.2.5
fi

echo -n -e "\033]0;leopard.sh $pkgspec ($(hostname -s))\007

binpkg=$pkgspec.$(leopard.sh --os.cpu).tar.gz
if curl -sSfI $LEOPARDSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$LEOPARDSH_FORCE_BUILD" ; then
    cd /opt
    curl -#f $LEOPARDSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else
    srcmirror=https://sourceforge.net/projects/$package/files/$package
    tarball=$package-$version.tar.xz

    if ! test -e ~/Downloads/$tarball ; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    cd /tmp
    rm -rf $package-$version
    tar xzf ~/Downloads/$tarball
    cd $package-$version
    ./configure -C --prefix=/opt/$pkgspec

    # The OS X ld does not support '-z' nor 'relro'.
    cat Makefile \
        | /usr/bin/sed 's/^HARDEN_LDFLAGS.*/HARDEN_LDFLAGS=/' \
        | /usr/bin/sed 's/^AM_LDFLAGS.*/AM_LDFLAGS=/' \
        > /tmp/Makefile
    mv /tmp/Makefile .

    make $(leopard.sh -j)

    if test -n "$LEOPARDSH_RUN_TESTS" ; then
        make check
    fi

    # FIXME: fails with:
    # Undefined symbols:
    #   "_getline", referenced from:
    #       _kill_all in killall.o
    # ld: symbol(s) not found
    # See:
    # https://forums.macrumors.com/threads/unable-to-compile-c-program-with-getline-using-gcc.1308709/?post=14163145#post-14163145
    # https://opensource.apple.com/source/cvs/cvs-42/cvs/lib/getline.h.auto.html
    # https://opensource.apple.com/source/cvs/cvs-42/cvs/lib/getline.c.auto.html
    # https://opensource.apple.com/source/cvs/cvs-42/cvs/lib/getdelim.h.auto.html
    # https://opensource.apple.com/source/cvs/cvs-42/cvs/lib/getdelim.c.auto.html
    make install

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
