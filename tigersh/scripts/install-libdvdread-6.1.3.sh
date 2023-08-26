#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install libdvdread on OS X Tiger / PowerPC.

package=libdvdread
version=6.1.3
upstream=https://download.videolan.org/pub/videolan/libdvdread/$version/libdvdread-$version.tar.bz2
description="Library for reading DVDs"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

# libdvdcss-1.4.3 is unavailable on tiger/ppc64.
if test -n "$ppc64" ; then
    exit 1
fi

dep=libdvdcss-1.4.3$ppc64
if ! test -e /opt/$dep ; then
    tiger.sh $dep
    CPPFLAGS="-I/opt/libdvdcss-1.4.3$ppc64/include"
    LDFLAGS="-L/opt/libdvdcss-1.4.3$ppc64/lib"
    LIBS="-ldvdcss"
fi

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

if tiger.sh --install-binpkg $pkgspec ; then
    exit 0
fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    tiger.sh xcode-2.5
fi

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

tiger.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

CFLAGS="$(tiger.sh -mcpu -O) $CFLAGS"
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

/usr/bin/time make $(tiger.sh -j) V=1

# Note: no 'make check' available.

make install

tiger.sh --linker-check $pkgspec
tiger.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
fi
