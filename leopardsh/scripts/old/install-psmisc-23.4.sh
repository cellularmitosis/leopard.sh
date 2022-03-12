#!/bin/bash

# Install psmisc on OS X Leopard / PowerPC.

package=psmisc
version=23.4

set -e -x -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

if ! which -s xz ; then
    leopard.sh xz-5.2.5
fi

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --os.cpu))\007"

if leopard.sh --install-binpkg $pkgspec ; then
    exit 0
fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    leopard.sh xcode-3.1.4
fi

leopard.sh --unpack-dist $pkgspec
    cd /tmp/$package-$version


    /usr/bin/time ./configure -C --prefix=/opt/$pkgspec

    # The OS X ld does not support '-z' nor 'relro'.
    cat Makefile \
        | /usr/bin/sed 's/^HARDEN_LDFLAGS.*/HARDEN_LDFLAGS=/' \
        | /usr/bin/sed 's/^AM_LDFLAGS.*/AM_LDFLAGS=/' \
        > /tmp/Makefile
    mv /tmp/Makefile .

    /usr/bin/time make $(leopard.sh -j)

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

    leopard.sh --linker-check $pkgspec
    leopard.sh --arch-check $pkgspec $ppc64

    if test -e config.cache ; then
        mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
        gzip -9 config.cache
        mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
    fi
fi


