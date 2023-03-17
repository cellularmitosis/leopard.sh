#!/bin/bash
# based on templates/build-from-source.sh v6

# Install cmake on OS X Leopard / PowerPC.

package=cmake
# Note: 3.9.6 was the last version which didn't require C++11.
version=3.9.6
upstream=https://cmake.org/files/v3.9/cmake-3.9.6.tar.gz
description="Cross platform Make"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

# Fails to build on leopard, but surprisingly, not on tiger:
#   [ 95%] Linking CXX executable ../bin/cmake
#   Undefined symbols:
#     "___sync_val_compare_and_swap", referenced from:
#         _cmpxchgi in libcmlibuv.a(async.c.o)
#   ld: symbol(s) not found
#   collect2: ld returned 1 exit status
#   make[2]: *** [bin/cmake] Error 1
#   make[1]: *** [Source/CMakeFiles/cmake.dir/all] Error 2
# For now, we'll just install the tiger package on leopard.
if leopard.sh --install-binpkg $pkgspec tiger.g4 ; then
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

/usr/bin/time \
    env CFLAGS="$CFLAGS" CXXFLAGS="$CXXFLAGS" \
        ./configure --prefix=/opt/$pkgspec

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
