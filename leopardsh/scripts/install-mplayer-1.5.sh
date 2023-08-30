#!/bin/bash
# based on templates/build-from-source.sh v6

# Install mplayer on OS X Leopard / PowerPC.

package=mplayer
version=1.5
upstream=https://mplayerhq.hu/MPlayer/releases/MPlayer-$version.tar.gz
description="Movie player for Unix-like systems"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

for pair in \
"openssl-1.1.1t$ppc64 ssl" \
"sdl-1.2.15.20220129$ppc64 SDL" \
"libdvdnav-6.1.1$ppc64 dvdnav" \
"libdvdread-6.1.3$ppc64 dvdread" \
"libdvdcss-1.4.3$ppc64 dvdcss" \
"libjpeg-6b$ppc64 jpeg" \
"libpng-1.6.40$ppc64 png" \
"libgif-5.2.1$ppc64 gif" \
"freetype-2.13.0$ppc64 freetype" \
"fontconfig-2.14.1$ppc64 fontconfig" \
"twolame-0.4.0$ppc64 twolame" \
"libogg-1.3.5$ppc64 ogg" \
"libvorbis-1.3.7$ppc64 vorbis" \
"libtheora-1.1.1$ppc64 theora" \
"speex-1.2.1$ppc64 speex" \
"mpg123-1.31.2$ppc64 mpg123" \
"opus-1.1.2$ppc64 opus" \
"libxml2-2.9.12$ppc64 xml2" \
"x264-ca5408b1$ppc64 x264" \
"lame-3.100$ppc64 mp3lame" \
; do
    depspec=$(echo $pair | awk '{print $1}')
    libname=$(echo $pair | awk '{print $2}')
    if ! test -e /opt/$depspec ; then
        leopard.sh $depspec
    fi
    CPPFLAGS="-I/opt/$depspec/include $CPPFLAGS"
    LDFLAGS="-L/opt/$depspec/lib $LDFLAGS"
    LIBS="-l$libname $LIBS"
    PATH="/opt/$depspec/bin:$PATH"
done

dep=macports-legacy-support-20221029$ppc64
if ! test -e /opt/$dep ; then
    leopard.sh $dep
fi
CPPFLAGS="-I/opt/$dep/include/LegacySupport $CPPFLAGS"
LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
LIBS="-lMacportsLegacySupport $LIBS"

if ! test -e /opt/mplayer-binary-codecs-20041107 ; then
    leopard.sh mplayer-binary-codecs-20041107
fi

if ! test -e /opt/gcc-4.9.4 ; then
    leopard.sh gcc-libs-4.9.4
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

if ! which -s gcc-4.9 ; then
    leopard.sh gcc-4.9.4
fi
CC=gcc-4.9
CXX=g++-4.9
OBJC=gcc-4.9

if ! which -s pkg-config ; then
    leopard.sh pkg-config-0.29.2
fi
export PATH="/opt/pkg-config-0.29.2/bin:$PATH"
PKG_CONFIG_PATH="/usr/local/lib/pkgconfig"

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

leopard.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

/usr/bin/time \
    env CC="$CC" CXX="$CXX" PKG_CONFIG_PATH="$PKG_CONFIG_PATH" \
    ./configure --prefix=/opt/$pkgspec \
    --codecsdir="/opt/mplayer-binary-codecs-20041107/lib/codecs" \
    --enable-openssl-nondistributable \
    --enable-macosx-finder \
    --enable-macosx-bundle \
    --extra-cflags="$CPPFLAGS" \
    --extra-ldflags="$LDFLAGS" \
    --extra-libs-mplayer="$LIBS" \
    --extra-libs-mencoder="$LIBS" \
    | tee /tmp/mplayer.log

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
