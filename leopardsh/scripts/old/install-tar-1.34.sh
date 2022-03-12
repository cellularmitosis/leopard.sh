#!/bin/bash
# based on templates/install-foo-1.0.sh v3

# Install tar on OS X Leopard / PowerPC.

package=tar
version=1.34

set -e -x -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

if ! test -e /opt/gettext-0.21$ppc64 ; then
    leopard.sh gettext-0.21$ppc64
fi

if ! test -e /opt/libiconv-1.16$ppc64 ; then
    leopard.sh libiconv-1.16$ppc64
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


    if test -n "$ppc64" ; then
        CFLAGS="-m64 $(leopard.sh -mcpu -O)"
        export LDFLAGS=-m64
    else
        CFLAGS=$(leopard.sh -m32 -mcpu -O)
    fi
    export CFLAGS

    /usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
        --with-libiconv-prefix=/opt/libiconv-1.16$ppc64 \
        --with-libintl-prefix=/opt/gettext-0.21$ppc64

    /usr/bin/time make $(leopard.sh -j) V=1

    if test -n "$LEOPARDSH_RUN_TESTS" ; then
        make check
    fi

    make install

    leopard.sh --linker-check $pkgspec
    leopard.sh --arch-check $pkgspec $ppc64

    if test -e config.cache ; then
        mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
        gzip -9 config.cache
        mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
    fi
fi


