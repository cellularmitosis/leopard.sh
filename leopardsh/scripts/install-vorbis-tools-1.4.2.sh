#!/bin/bash
# based on templates/build-from-source.sh v6

# Install vorbis-tools on OS X Leopard / PowerPC.

package=vorbis-tools
version=1.4.2
upstream=https://downloads.xiph.org/releases/vorbis/$package-$version.tar.gz
description="Tools for using the Ogg Vorbis sound file format"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

for dep in \
    libogg-1.3.5$ppc64 \
    libvorbis-1.3.7$ppc64 \
    flac-1.4.2$ppc64 \
    speex-1.2.1$ppc64 \
    libao-1.2.0$ppc64 \
    curl-7.87.0$ppc64
do
    if ! test -e /opt/$dep ; then
        leopard.sh $dep
    fi
    CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
    LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
    PATH="/opt/$dep/bin:$PATH"
done
LIBS="-logg -lvorbis -lFLAC -lspeex -lao -lcurl"

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

if leopard.sh --install-binpkg $pkgspec ; then
    exit 0
fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    leopard.sh xcode-3.1.4
fi

if ! which -s pkg-config ; then
    leopard.sh pkg-config-0.29.2
fi
export PATH="/opt/pkg-config-0.29.2/bin:$PATH"

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
    --enable-ogg123 \
    --enable-vcut \
    --with-ogg=/opt/libogg-1.3.5$ppc64 \
    --with-vorbis=/opt/libvorbis-1.3.7$ppc64 \
    --with-curl=/opt/curl-7.87.7$ppc64 \
    CFLAGS="$CFLAGS" \
    CXXFLAGS="$CXXFLAGS" \
    LDFLAGS="$LDFLAGS" \
    CPPFLAGS="$CPPFLAGS" \
    LIBS="$LIBS" \
    PKG_CONFIG=/opt/pkg-config-0.29.2/bin/pkg-config \
    PKG_CONFIG_PATH="/opt/libao-1.2.0$ppc64/lib/pkgconfig" \

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
