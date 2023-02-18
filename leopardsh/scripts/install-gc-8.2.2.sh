#!/bin/bash
# based on templates/build-from-source.sh v6

# Install gc on OS X Leopard / PowerPC.

package=gc
version=8.2.2
upstream=https://www.hboehm.info/gc/gc_source/$package-$version.tar.gz
description="The Boehm-Demers-Weiser conservative garbage collector"

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

atomic_version=7.6.14
atomic_tarball=libatomic_ops-${atomic_version}.tar.gz
atomic_url=$LEOPARDSH_MIRROR/dist/$atomic_tarball
echo -e "${COLOR_CYAN}Unpacking${COLOR_NONE} $atomic_tarball into /tmp/$package-$version." >&2
leopard.sh --unpack-tarball-check-md5 $atomic_url /tmp/$package-$version
mv libatomic_ops-${atomic_version} libatomic_ops

CFLAGS=$(leopard.sh -mcpu -O)
CXXFLAGS=$(leopard.sh -mcpu -O)
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    CXXFLAGS="-m64 $CXXFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --enable-cplusplus \
    --enable-static \
    LDFLAGS="$LDFLAGS" \
    CFLAGS="$CFLAGS" \
    CXXFLAGS="$CXXFLAGS"

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
