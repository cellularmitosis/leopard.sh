#!/bin/bash
# based on templates/build-from-source.sh v6

# Install libuv on OS X Leopard / PowerPC.

package=libuv
version=1.44.2
upstream=https://github.com/libuv/libuv/archive/refs/tags/v$version.tar.gz
description="Cross-platform asychronous I/O"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

dep=macports-legacy-support-20221029$ppc64
if ! test -e /opt/$dep ; then
    leopard.sh $dep
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

if ! which -s gcc-4.2 ; then
    leopard.sh gcc-4.2
fi
CC=gcc-4.2
CXX=g++-4.2

for dep in autoconf-2.71 autogen-5.18.16 automake-1.16.5 libtool-2.4.6 ; do
    leopard.sh $dep
    PATH="/opt/$dep/bin:$PATH"
done

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

leopard.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

LIBTOOLIZE=libtoolize ./autogen.sh

# Many thanks to the MacPorts team!
for pair in \
    "-p0 patch-libuv-legacy.diff" \
    "-p0 patch-libuv-unix-core-close-nocancel.diff" \
    "-p0 patch-no-libutil-on-Tiger.diff" \
; do
    plevel=$(echo $pair | cut -d' ' -f1)
    pfile=$(echo $pair | cut -d' ' -f2)
    url=https://raw.githubusercontent.com/macports/macports-ports/master/devel/libuv/files/$pfile
    curl --fail --silent --show-error --location --remote-name $url
    patch $plevel < $pfile
done

CFLAGS="$(leopard.sh -mcpu -O) $CFLAGS"
CXXFLAGS="$(leopard.sh -mcpu -O) $CXXFLAGS"
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    CXXFLAGS="-m64 $CXXFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

CPPFLAGS="-I/opt/macports-legacy-support-20221029$ppc64/include/LegacySupport $CPPFLAGS"
LDFLAGS="-L/opt/macports-legacy-support-20221029$ppc64/lib $LDFLAGS"
LIBS="-lMacportsLegacySupport $LIBS"

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --disable-dependency-tracking \
    CPPFLAGS="$CPPFLAGS" \
    CFLAGS="$CFLAGS" \
    CXXFLAGS="$CXXFLAGS" \
    LDFLAGS="$LDFLAGS" \
    LIBS="$LIBS" \
    CC="$CC" \
    CXX="$CXX"

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
