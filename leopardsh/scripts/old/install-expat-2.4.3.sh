#!/bin/bash

# Install expat on OS X Leopard / PowerPC.

package=expat
version=2.4.3

set -e -x -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

# if ! test -e /opt/m4-1.4.19$ppc64 ; then
#     leopard.sh m4-1.4.19$ppc64
# fi

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --os.cpu))\007"

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

perl -pi -e "s/CFLAGS=\"-g -O2\"/CFLAGS=\"$(leopard.sh -m32 -mcpu -O)\"/g" configure
perl -pi -e "s/CXXFLAGS=\"-g -O2\"/CXXFLAGS=\"$(leopard.sh -m32 -mcpu -O)\"/g" configure

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec
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
