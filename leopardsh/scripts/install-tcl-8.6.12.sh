#!/bin/bash
# based on templates/build-from-source.sh v6

# Install tcl on OS X Leopard / PowerPC.

package=tcl
version=8.6.12
upstream=https://prdownloads.sourceforge.net/tcl/tcl$version-src.tar.gz
description="Tool Command Language"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

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

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

leopard.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

CFLAGS=$(leopard.sh -mcpu -O)
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    B64="--enable-64bit"
fi

# We'll provide our own optimization flags.
sed -i '' -e 's/CFLAGS_OPTIMIZE="-Os"/CFLAGS_OPTIMIZE=""/g' unix/configure

cd unix
/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --enable-threads \
    --enable-shared \
    --enable-load \
    --disable-rpath \
    --enable-corefoundation \
    $B64 \
    CFLAGS="$CFLAGS"

# Note: --enable-framework violates --prefix and causes lots of things to be
# written to /Library/Frameworks/Tcl.framework.

# The original source distribution comes in a directory named 'tcl8.6.12',
# which I rename to 'tcl-8.6.12'.
# The Makefile needs to be patched to account for this:
sed -i '' -e 's|s/tcl//|s/tcl-//|' Makefile

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
