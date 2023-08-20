#!/bin/bash
# based on templates/build-from-source.sh v6

# Install libtiff on OS X Leopard / PowerPC.

package=libtiff
version=4.5.1
upstream=http://download.osgeo.org/libtiff/tiff-$version.tar.gz
description="Tag Image File Format library"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

for dep in \
    libjpeg-6b$ppc64 \
    xz-5.2.5$ppc64 \
    zstd-1.5.1$ppc64
do
    if ! test -e /opt/$dep ; then
        leopard.sh $dep
    fi
done

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
CXXFLAGS="$(leopard.sh -mcpu -O) $CXXFLAGS"
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    CXXFLAGS="-m64 $CXXFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --disable-dependency-tracking \
    --disable-maintainer-mode \
    --disable-debug \
    CFLAGS="$CFLAGS" \
    CXXFLAGS="$CXXFLAGS" \
    LDFLAGS="$LDFLAGS" \
    --with-jpeg-include-dir=/opt/libjpeg-6b$ppc64/include \
    --with-jpeg-lib-dir=/opt/libjpeg-6b$ppc64/lib \
    --with-zstd-include-dir=/opt/zstd-1.5.1$ppc64/include \
    --with-zstd-lib-dir=/opt/zstd-1.5.1$ppc64/lib \
    --with-lzma-include-dir=/opt/xz-5.2.5$ppc64/include \
    --with-lzma-lib-dir=/opt/xz-5.2.5$ppc64/lib

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
