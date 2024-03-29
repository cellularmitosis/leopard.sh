#!/bin/bash
# based on templates/build-from-source.sh v6

# Install isl on OS X Leopard / PowerPC.

package=isl
version=0.24
upstream=https://gcc.gnu.org/pub/gcc/infrastructure/$package-$version.tar.bz2

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
    # Note: not building on ppc64 yet:
    # ld warning: in isl_test.o, file is not of required architecture
    exit 1
fi

pkgspec=$package-$version$ppc64

for dep in \
    gmp-6.2.1$ppc64
do
    if ! test -e /opt/$dep ; then
        leopard.sh $dep
    fi
    CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
    LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
done

if ! test -e /usr/bin/gcc ; then
    leopard.sh xcode-3.1.4
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

leopard.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

CC=gcc-4.9

CFLAGS="$(leopard.sh -mcpu -O) -fomit-frame-pointer -fstrict-aliasing -ffast-math"
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --with-gmp-prefix=/opt/gmp-6.2.1$ppc64 \
    LDFLAGS="$LDFLAGS" \
    CFLAGS="$CFLAGS" \
    CC="$CC"

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
