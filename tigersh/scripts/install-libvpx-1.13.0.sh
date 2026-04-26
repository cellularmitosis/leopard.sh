#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install libvpx on OS X Tiger / PowerPC.

package=libvpx
version=1.13.0
upstream=https://github.com/webmproject/libvpx/archive/refs/tags/v$version.tar.gz
description="VP8/VP9 Codec"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

if ! test -e /opt/gcc-10.3.0 ; then
    tiger.sh gcc-libs-10.3.0
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

if ! type -a gcc-10.3 >/dev/null 2>&1 ; then
    tiger.sh gcc-10.3.0
fi
CC=gcc-10.3
CXX=g++-10.3
LD=gcc-10.3

if ! test -e /opt/ld64-97.17-tigerbrew ; then
    tiger.sh ld64-97.17-tigerbrew
fi
export PATH="/opt/ld64-97.17-tigerbrew/bin:$PATH"
CC="$CC -B/opt/ld64-97.17-tigerbrew/bin"
OBJC="$OBJC -B/opt/ld64-97.17-tigerbrew/bin"
CXX="$CXX -B/opt/ld64-97.17-tigerbrew/bin"
LD="$LD -B/opt/ld64-97.17-tigerbrew/bin"

dep=make-4.3
if ! test -e /opt/$dep ; then
    tiger.sh $dep
    PATH="/opt/$dep/bin:$PATH"
fi

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

tiger.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

CFLAGS="$(tiger.sh -mcpu -O) $CFLAGS"
CXXFLAGS="$(tiger.sh -mcpu -O) $CXXFLAGS"
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    CXXFLAGS="-m64 $CXXFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

/usr/bin/time env \
    CFLAGS="$CFLAGS" \
    CXXFLAGS="$CXXFLAGS" \
    LDFLAGS="$LDFLAGS" \
    CC="$CC" \
    CXX="$CXX" \
    LD="$LD -lstdc++" \
    ./configure --prefix=/opt/$pkgspec \
        --disable-dependency-tracking \
        --disable-debug \
        --disable-examples \
        --enable-shared

for f in tools-generic-gnu.mk libs-generic-gnu.mk docs-generic-gnu.mk ; do
    sed -i '' -e 's| -O3 ||' $f
done

for f in Makefile build/make/Makefile ; do
    sed -i '' -e 's|-Wl,--no-undefined ||' $f
done

/usr/bin/time make $(tiger.sh -j) CC="$CC" CXX="$CXX" LD="$LD" V=1

# 👇 EDIT HERE:
if test -n "$TIGERSH_RUN_TESTS" ; then
    make check
fi

# 👇 EDIT HERE:
# if test -n "$TIGERSH_RUN_BROKEN_TESTS" ; then
#     make check
# fi

# 👇 EDIT HERE:
# if test -n "$TIGERSH_RUN_LONG_TESTS" ; then
#     make check
# fi

# 👇 EDIT HERE:
# Note: no 'make check' available.

make install

tiger.sh --linker-check $pkgspec
tiger.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
fi
