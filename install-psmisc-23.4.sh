#!/bin/bash

# Install psmisc on OS X Leopard / PowerPC.

package=psmisc
version=23.4

set -e -x -o pipefail
PATH="/opt/portable-curl/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://ssl.pepas.com/leopardsh}

if ! which -s xz; then
    leopard.sh xz-5.2.5
fi

echo -n -e "\033]0;Installing $package-$version\007"

binpkg=$package-$version.$(leopard.sh --os.cpu).tar.gz
if curl -sSfI $LEOPARDSH_MIRROR/$binpkg >/dev/null 2>&1 && test -z "$LEOPARDSH_FORCE_BUILD"; then
    cd /opt
    curl -#f $LEOPARDSH_MIRROR/$binpkg | gunzip | tar x
else
    srcmirror=https://sourceforge.net/projects/$package/files/$package
    tarball=$package-$version.tar.xz

    if ! test -e ~/Downloads/$tarball; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    cd /tmp
    rm -rf $package-$version
    tar xzf ~/Downloads/$tarball
    cd $package-$version
    ./configure --prefix=/opt/$package-$version

    # The OS X ld does not support '-z' nor 'relro'.
    cat Makefile \
        | /usr/bin/sed 's/^HARDEN_LDFLAGS.*/HARDEN_LDFLAGS=/' \
        | /usr/bin/sed 's/^AM_LDFLAGS.*/AM_LDFLAGS=/' \
        > /tmp/Makefile
    mv /tmp/Makefile .

    make

    if test -n "$LEOPARDSH_MAKE_CHECK"; then
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
fi

ln -sf /opt/$package-$version/bin/* /usr/local/bin/
