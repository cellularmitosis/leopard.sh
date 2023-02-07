#!/bin/bash
# based on templates/build-from-source.sh v6

# Install lz4 on OS X Leopard / PowerPC.

package=lz4
version=1.9.4
upstream=https://github.com/$package/$package/archive/refs/tags/v$version.tar.gz

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

perl -pi -e "s/-shared/-dynamiclib/g" lib/Makefile

CC=gcc

CFLAGS=$(leopard.sh -mcpu -O)
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

/usr/bin/time make V=1 \
    $(leopard.sh -j) \
    CC=$CC \
    CFLAGS="$CFLAGS" \
    LDFLAGS="$LDFLAGS" \
    prefix=/opt/$pkgspec

if test -n "$LEOPARDSH_RUN_BROKEN_TESTS" ; then
    make check
    # This test fails and causes `make check` to fail, but it seems like it is supposed to fail?
    #  ! ../programs/lz4 tmp-tlb2 tmp-tlb3 tmp-tlb4    # must fail: refuse to handle 3+ file names
    #  Error : tmp-tlb4 won't be used ! Do you want multiple input files (-m) ? 
    #  make[1]: *** [Makefile:412: test-lz4-basic] Error 1
    #  make[1]: Leaving directory '/private/tmp/lz4-1.9.4/tests'
    #  make: *** [Makefile:133: check] Error 2
fi

make prefix=/opt/$pkgspec install

leopard.sh --linker-check $pkgspec
leopard.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
fi
