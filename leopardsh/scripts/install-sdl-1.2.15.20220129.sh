#!/bin/bash
# based on templates/build-from-source.sh v6

# Install SDL 1.2 on OS X Leopard / PowerPC.

package=sdl
version=1.2.15.20220129
upstream=https://github.com/libsdl-org/SDL-1.2/archive/707e2cc25904bd4ea7ca94f45632e02d7dbee14c.tar.gz

set -e -x -o pipefail
PATH="/opt/portable-curl/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://ssl.pepas.com/leopardsh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

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

# Note: we have to do a bit of flag hackery here to avoid the dylib reporting the wrong arch:
#   Non-fat file: lib/libSDL-1.2.0.dylib is architecture: ppc
CC="gcc $(leopard.sh -mcpu -O)"

CFLAGS=$(leopard.sh -mcpu -O)
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
    CC="$CC -m64"
fi

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --disable-oss \
    --disable-alsa \
    --disable-esd \
    --disable-sndio \
    --disable-pulseaudio \
    --disable-nas \
    --disable-video-photon \
    --disable-video-fbcon \
    --disable-video-directfb \
    --disable-video-ps2gs \
    --disable-video-ps3 \
    --disable-video-svga \
    --disable-video-vgl \
    --disable-video-wscons \
    --disable-input-tslib \
    --disable-video-grop \
    --disable-directx \
    CFLAGS="$CFLAGS" \
    LDFLAGS="$LDFLAGS" \
    CC="$CC"

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
