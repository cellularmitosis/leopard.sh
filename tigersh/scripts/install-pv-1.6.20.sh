#!/bin/bash
# based on templates/build-from-source.sh v5

# Install pv on OS X Tiger / PowerPC.

package=pv
version=1.6.20

set -e
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --os.cpu))\007"

if tiger.sh --install-binpkg $pkgspec ; then
    exit 0
fi

echo "Building $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    tiger.sh xcode-2.5
fi

upstream=https://distfiles.gentoo.org/distfiles/$package-$version.tar.bz2

tiger.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

cat /opt/tiger.sh/share/tiger.sh/config.cache/tiger.cache > config.cache

CFLAGS=$(tiger.sh -mcpu -O)
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
fi

/usr/bin/time \
    ./configure -C --prefix=/opt/$pkgspec \
        CFLAGS="$CFLAGS" \
    && make $(tiger.sh -j)

if test -n "$TIGERSH_RUN_TESTS" ; then
    make check
fi

make install

tiger.sh --linker-check $pkgspec
tiger.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
    gzip config.cache
    mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
fi
