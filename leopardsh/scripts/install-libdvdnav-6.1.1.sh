#!/bin/bash
# based on templates/build-from-source.sh v6

# Install libdvdnav on OS X Leopard / PowerPC.

package=libdvdnav
version=6.1.1
upstream=https://download.videolan.org/pub/videolan/libdvdnav/$version/libdvdnav-$version.tar.bz2
description="Library for DVD navigation tools"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

dep=libdvdread-6.1.3$ppc64
if ! test -e /opt/$dep ; then
    leopard.sh $dep
fi

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

if leopard.sh --install-binpkg $pkgspec ; then
    exit 0
fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    leopard.sh xcode-3.1.4
fi

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

leopard.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

CFLAGS="$(leopard.sh -mcpu -O) $CFLAGS"
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

/usr/bin/time env \
    DVDREAD_CFLAGS="-I/opt/libdvdread-6.1.3$ppc64/include -L/opt/libdvdread-6.1.3$ppc64/lib" \
    DVDREAD_LIBS="-L/opt/libdvdread-6.1.3$ppc64/lib -ldvdread" \
    ./configure -C --prefix=/opt/$pkgspec \
        --disable-dependency-tracking \
        CFLAGS="$CFLAGS" \
        LDFLAGS="$LDFLAGS"

/usr/bin/time make $(leopard.sh -j) V=1

# Note: no 'make check' available.

make install

leopard.sh --linker-check $pkgspec
leopard.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
fi
