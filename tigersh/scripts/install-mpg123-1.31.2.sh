#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install mpg123 on OS X Tiger / PowerPC.

package=mpg123
version=1.31.2
upstream=https://www.mpg123.de/download/$package-$version.tar.bz2
description="A realtime MPEG 1.0/2.0/2.5 audio player for layers 1, 2 and 3"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

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
CXXFLAGS="$(tiger.sh -mcpu -O) $CFLAGS"
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    CXXFLAGS="-m64 $CXXFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

# Note: the two audio drivers natively supported by OS X are CoreAudio and OpenAL.
# However, Tiger doesn't ship with 64-bit versions of these frameworks, so for
# the ppc64 build we only include the dummy driver.  This makes the player useless
# but perhaps the 64-bit libs are useful.
if test -n "$ppc64" ; then
    drivers="--with-audio=dummy"
fi

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --disable-dependency-tracking \
    $drivers \
    CFLAGS="$CFLAGS" \
    CXXFLAGS="$CXXFLAGS" \

/usr/bin/time make $(tiger.sh -j) V=1

if test -n "$TIGERSH_RUN_TESTS" ; then
    make check
fi

# Note: test it out with:
#   curl -O http://leopard.sh/misc/av-clips/strangelove/44k-vbr0-2ch.mp3
#   mpg123 44k-vbr0-2ch.mp3

make install

tiger.sh --linker-check $pkgspec
tiger.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
fi
