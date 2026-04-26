#!/bin/bash
# based on templates/build-from-source.sh v6

# Install libvpx on OS X Leopard / PowerPC.

package=libvpx
version=1.13.0
upstream=https://github.com/webmproject/libvpx/archive/refs/tags/v$version.tar.gz
description="VP8/VP9 Codec"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

if ! test -e /opt/gcc-10.3.0 ; then
    leopard.sh gcc-libs-10.3.0
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

if ! type -a gcc-10.3 >/dev/null 2>&1 ; then
    leopard.sh gcc-10.3.0
fi
CC=gcc-10.3
CXX=g++-10.3
LD=gcc-10.3


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

/usr/bin/time make $(leopard.sh -j) CC="$CC" CXX="$CXX" LD="$LD" V=1

# Undefined symbols:
#   "__Unwind_Resume", referenced from:
# see https://stackoverflow.com/a/22774664/558735

# 👇 EDIT HERE:
if test -n "$LEOPARDSH_RUN_TESTS" ; then
    make check
fi

# 👇 EDIT HERE:
# if test -n "$LEOPARDSH_RUN_BROKEN_TESTS" ; then
#     make check
# fi

# 👇 EDIT HERE:
# if test -n "$LEOPARDSH_RUN_LONG_TESTS" ; then
#     make check
# fi

# 👇 EDIT HERE:
# Note: no 'make check' available.

make install

leopard.sh --linker-check $pkgspec
leopard.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
fi
