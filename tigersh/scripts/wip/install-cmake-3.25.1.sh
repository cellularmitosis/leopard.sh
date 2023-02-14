#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install cmake on OS X Tiger / PowerPC.

package=cmake
version=3.25.1
upstream=https://cmake.org/files/v3.25/cmake-3.25.1.tar.gz

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

if ! type -a gcc-4.9 >/dev/null 2>&1 ; then
    tiger.sh gcc-4.9.4
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

CC=gcc-4.9
CXX=g++-4.9

CFLAGS=$(tiger.sh -mcpu -O)
CXXFLAGS=$(tiger.sh -mcpu -O)
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    CXXFLAGS="-m64 $CXXFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    LDFLAGS="$LDFLAGS" \
    CFLAGS="$CFLAGS" \
    CXXFLAGS="$CXXFLAGS" \
    CC="$CC" \
    CXX="$CXX"

/usr/bin/time make $(tiger.sh -j) V=1

if test -n "$TIGERSH_RUN_TESTS" ; then
    make check
fi

make install

tiger.sh --linker-check $pkgspec
tiger.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
fi
