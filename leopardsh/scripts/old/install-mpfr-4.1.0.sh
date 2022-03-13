#!/bin/bash

# Install mpfr on OS X Leopard / PowerPC.

package=mpfr
version=4.1.0

set -e -x -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

if ! test -e /opt/gmp-6.2.1$ppc64 ; then
    leopard.sh gmp-6.2.1$ppc64
fi

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --os.cpu))\007"

if leopard.sh --install-binpkg $pkgspec ; then
    exit 0
fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    leopard.sh xcode-3.1.4
fi

if ! test -e /opt/gcc-4.9.4$ppc64 ; then
    leopard.sh gcc-4.9.4$ppc64
fi

leopard.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

# Note: --enabled-thread-safe requires TLS (thread-local storage),
# which was supported as of gcc 4.9.
CC=/opt/gcc-4.9.4/bin/gcc /usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --enable-thread-safe \
    --with-gmp=/opt/gmp-6.2.1$ppc64

/usr/bin/time make $(leopard.sh -j)

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
