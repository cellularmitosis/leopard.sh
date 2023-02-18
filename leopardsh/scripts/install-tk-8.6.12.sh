#!/bin/bash
# based on templates/build-from-source.sh v6

# Install tk on OS X Leopard / PowerPC.

package=tk
version=8.6.12
upstream=https://prdownloads.sourceforge.net/tcl/tk$version-src.tar.gz
description="GUI toolkit for Tcl"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

for dep in \
    tcl-8.6.12$ppc64
do
    if ! test -e /opt/$dep ; then
        leopard.sh $dep
    fi
    CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
    LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
    PATH="/opt/$dep/bin:$PATH"
done

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

if leopard.sh --install-binpkg $pkgspec ; then
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

CFLAGS=$(leopard.sh -mcpu -O)
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
    B64="--enable-64bit"
fi

cd unix
/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --disable-dependency-tracking \
    --with-tcl=/opt/tcl-8.6.12$ppc64/lib \
    --with-x \
    --enable-threads \
    --enable-shared \
    --enable-load \
    --disable-rpath \
    --enable-corefoundation \
    $B64 \
    CPPFLAGS="$CPPFLAGS" \
    LDFLAGS="$LDFLAGS" \
    CFLAGS="$CFLAGS" \

# Note: --enable-aqua uses e.g. NSMenuDelegate, which wasn't introduced until
# 10.6 (Snow Leopard).  Note that tk's configure script incorrectly checks for 10.5.

/usr/bin/time make $(leopard.sh -j) V=1

if test -n "$LEOPARDSH_RUN_TESTS" ; then
    make test
fi

make install

leopard.sh --linker-check $pkgspec
leopard.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
fi
