#!/bin/bash
# based on templates/build-from-source.sh v6

# Install libdvdread on OS X Leopard / PowerPC.

package=libdvdread
version=6.1.3
upstream=https://download.videolan.org/pub/videolan/libdvdread/$version/libdvdread-$version.tar.bz2
description="Library for reading DVDs"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

dep=libdvdcss-1.4.3$ppc64
if ! test -e /opt/$dep ; then
    leopard.sh $dep
    CPPFLAGS="-I/opt/libdvdcss-1.4.3$ppc64/include"
    LDFLAGS="-L/opt/libdvdcss-1.4.3$ppc64/lib"
    LIBS="-ldvdcss"
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

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --disable-dependency-tracking \
    --disable-maintainer-mode \
    --with-libdvdcss \
    CFLAGS="$CFLAGS" \
    CPPFLAGS="$CPPFLAGS" \
    LDFLAGS="$LDFLAGS" \
    LIBS="$LIBS" \
    CSS_CFLAGS="-I/opt/libdvdcss-1.4.3/include" \
    CSS_LIBS="-ldvdcss"

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
