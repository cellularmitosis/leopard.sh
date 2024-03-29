#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install macports-legacy-support on OS X Tiger / PowerPC.

package=macports-legacy-support
version=20221029
upstream=https://github.com/macports/$package/archive/refs/heads/master.tar.gz
description="Support for missing functions in legacy OS X versions"

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

if ! type -a gcc-4.2 >/dev/null 2>&1 ; then
    tiger.sh gcc-4.2
fi

if ! test -e /opt/cctools-667.3 ; then
    tiger.sh cctools-667.3
fi
export PATH="/opt/cctools-667.3/bin:$PATH"

if ! test -e /opt/ld64-97.17 ; then
    tiger.sh ld64-97.17-tigerbrew
fi
export PATH="/opt/ld64-97.17/bin:$PATH"

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

tiger.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

# From https://github.com/macports/macports-ports/blob/master/devel/legacy-support/Portfile:
#   until upstream can be fixed, do not include atexit symbols
#   under certain circumstances, infinite recursive loops can form
rm src/macports_legacy_atexit.c

# Tiger's ld doesn't understand -reexport_library, which we can solve with ld64-97.17.
# However, /usr/bin/gcc will try to use libtool rather than ld, so we need gcc-4.2.
CC='gcc-4.2 -B/opt/ld64-97.17-tigerbrew/bin'
CXX='g++-4.2 -B/opt/ld64-97.17-tigerbrew/bin'

CFLAGS=$(tiger.sh -mcpu -O)
CXXFLAGS=$(tiger.sh -mcpu -O)
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    CXXFLAGS="-m64 $CXXFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

CFLAGS="$CFLAGS -I/tmp/$package-$version/tiger_only/include"

arch=ppc
if test -n "$ppc64" ; then
    arch=ppc64
fi

/usr/bin/time make PREFIX=/opt/$pkgspec \
    CFLAGS="$CFLAGS" \
    CXXFLAGS="$CXXFLAGS" \
    LDFLAGS="$LDFLAGS" \
    CC="$CC" \
    CXX="$CXX" \
    FORCE_ARCH=$arch

if test -n "$TIGERSH_RUN_BROKEN_TESTS" ; then
    make PREFIX=/opt/$pkgspec \
        CFLAGS="$CFLAGS" \
        CXXFLAGS="$CXXFLAGS" \
        LDFLAGS="$LDFLAGS" \
        CC="$CC" \
        CXX="$CXX" \
        FORCE_ARCH=$arch \
        check
fi

make PREFIX=/opt/$pkgspec \
    CFLAGS="$CFLAGS" \
    CXXFLAGS="$CXXFLAGS" \
    LDFLAGS="$LDFLAGS" \
    CC="$CC" \
    CXX="$CXX" \
    FORCE_ARCH=$arch \
    install

mkdir -p /opt/$pkgspec/bin
rsync -av tiger_only/bin/ /opt/$pkgspec/bin/
rsync -av tiger_only/include/ /opt/$pkgspec/include/LegacySupport/

tiger.sh --linker-check $pkgspec
tiger.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
fi
