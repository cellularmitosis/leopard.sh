#!/bin/bash
# based on templates/build-from-source.sh v6

# Install SPIM on OS X Leopard / PowerPC.

package=spim
version=r754
upstream=https://sourceforge.net/code-snapshots/svn/s/sp/spimsimulator/code/spimsimulator-code-r754.zip
description="MIPS CPU simulator"

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

cd spim
make PREFIX=/opt/spim-r754 install
if test -n "$LEOPARDSH_RUN_TESTS" ; then
    make test
fi
cd -

cd xspim
make PREFIX=/opt/spim-r754 EXTRA_LDOPTIONS="-L/usr/X11/lib -lstdc++" install
cd -

leopard.sh --linker-check $pkgspec
leopard.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
fi
