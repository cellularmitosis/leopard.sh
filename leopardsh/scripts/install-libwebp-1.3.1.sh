#!/bin/bash
# based on templates/build-from-source.sh v6

# Install libwebp on OS X Leopard / PowerPC.

package=libwebp
version=1.3.1
upstream=https://storage.googleapis.com/downloads.webmproject.org/releases/webp/$package-$version.tar.gz
description="WebP image format codec"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

for dep in \
    libjpeg-6b$ppc64 \
    libpng-1.6.40$ppc64 \
    libtiff-4.5.1$ppc64 \
    libgif-5.2.1$ppc64
do
    if ! test -e /opt/$dep ; then
        leopard.sh $dep
    fi
    CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
    LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
    PATH="/opt/$dep/bin:$PATH"
    PKG_CONFIG_PATH="$PKG_CONFIG_PATH:/opt/$dep/lib/pkgconfig"
done
LIBS="-lbar -lqux"
PKG_CONFIG_PATH="$(echo $PKG_CONFIG_PATH | sed -e 's/^://')"

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

if leopard.sh --install-binpkg $pkgspec ; then
    exit 0
fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    leopard.sh xcode-3.1.4
fi

# 👇 EDIT HERE:
if ! which -s gcc-4.2 ; then
    leopard.sh gcc-4.2
fi
CC=gcc-4.2
CXX=g++-4.2

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
    --disable-debug \
    CFLAGS="$CFLAGS" \
    CXXFLAGS="$CXXFLAGS" \
    LDFLAGS="$LDFLAGS" \
    CC="$CC" \
    CXX="$CXX" \
    --with-jpegincludedir=/opt/libjpeg-6b$ppc64/include \
    --with-jpeglibdir=/opt/libjpeg-6b$ppc64/lib \
    --with-pngincludedir=/opt/libpng-1.6.40$ppc64/include \
    --with-pnglibdir=/opt/libpng-1.6.40$ppc64/lib \
    --with-tiffincludedir=/opt/libtiff-4.5.1$ppc64/include \
    --with-tifflibdir=/opt/libtiff-4.5.1$ppc64/lib \
    --with-gifincludedir=/opt/libgif-5.2.1$ppc64/include \
    --with-giflibdir=/opt/libgif-5.2.1$ppc64/lib \

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
