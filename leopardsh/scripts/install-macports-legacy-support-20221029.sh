#!/bin/bash
# based on templates/build-from-source.sh v6

# Install macports-legacy-support on OS X Leopard / PowerPC.

package=macports-legacy-support
version=20221029
upstream=https://github.com/macports/$package/archive/refs/heads/master.tar.gz
description="Support for missing functions in legacy OS X versions"

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

# From https://github.com/macports/macports-ports/blob/master/devel/legacy-support/Portfile:
#   until upstream can be fixed, do not include atexit symbols
#   under certain circumstances, infinite recursive loops can form
rm src/macports_legacy_atexit.c

CFLAGS=$(leopard.sh -mcpu -O)
CXXFLAGS=$(leopard.sh -mcpu -O)
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    CXXFLAGS="-m64 $CXXFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

arch=ppc
if test -n "$ppc64" ; then
    arch=ppc64
fi

/usr/bin/time make PREFIX=/opt/$pkgspec \
    CFLAGS="$CFLAGS" \
    CXXFLAGS="$CXXFLAGS" \
    LDFLAGS="$LDFLAGS" \
    FORCE_ARCH=$arch

if test -n "$LEOPARDSH_RUN_BROKEN_TESTS" ; then
    make PREFIX=/opt/$pkgspec \
        CFLAGS="$CFLAGS" \
        CXXFLAGS="$CXXFLAGS" \
        LDFLAGS="$LDFLAGS" \
        FORCE_ARCH=$arch \
        check
fi

make PREFIX=/opt/$pkgspec \
    CFLAGS="$CFLAGS" \
    CXXFLAGS="$CXXFLAGS" \
    LDFLAGS="$LDFLAGS" \
    FORCE_ARCH=$arch \
    install

leopard.sh --linker-check $pkgspec
leopard.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
fi
